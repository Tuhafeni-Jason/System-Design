import ballerina/grpc;
import ballerina/time;
import ballerina/uuid;
import ballerina/io;

// In-memory storage
map<User> users = {};                  // user_id -> User
map<Car> cars = {};                    // plate -> Car
map<Reservation[]> reservations = {};  // plate -> Reservation[] (for easy overlap check)
map<CartItem[]> carts = {};            // user_id -> CartItem[]

// Listener on port 9090
listener grpc:Listener ep = new (9090);

// The service implementation (extends generated abstract service)
@grpc:ServiceDescriptor {descriptor: ROOT_DESCRIPTOR_CAR_RENTAL}
service "CarRentalService" on ep {

    // Helper function to check if admin
    function isAdmin(string userId) returns boolean {
        User? user = users[userId];
        return user is User && user.role == "ADMIN";
    }

    // Helper to parse date string to time:Date
    function parseDate(string dateStr) returns time:Date|error {
        string[] parts = dateStr.split("-");
        if parts.length() != 3 {
            return error("Invalid date format");
        }
        return {
            year: check int:fromString(parts[0]),
            month: check int:fromString(parts[1]),
            day: check int:fromString(parts[2])
        };
    }

    // Helper to calculate days between dates
    function calculateDays(string start, string end) returns int|error {
        time:Date startDate = check parseDate(start);
        time:Date endDate = check parseDate(end);
        time:Civil startCivil = {year: startDate.year, month: startDate.month, day: startDate.day};
        time:Civil endCivil = {year: endDate.year, month: endDate.month, day: endDate.day};
        time:Seconds diff = time:subtract(endCivil, startCivil);
        return <int>(diff / (3600 * 24)) + 1;  // +1 for inclusive
    }

    // Helper to check if dates overlap with existing reservations
    function hasOverlap(string plate, string newStart, string newEnd) returns boolean|error {
        Reservation[]? resList = reservations[plate];
        if resList is Reservation[] {
            time:Date nStart = check parseDate(newStart);
            time:Date nEnd = check parseDate(newEnd);
            foreach Reservation r in resList {
                time:Date rStart = check parseDate(r.start_date);
                time:Date rEnd = check parseDate(r.end_date);
                if !(nEnd < rStart || nStart > rEnd) {  // Overlap condition
                    return true;
                }
            }
        }
        return false;
    }

    // addCar: Admin adds a car
    remote function addCar(AddCarRequest request) returns AddCarResponse|error {
        if !self.isAdmin(request.user_id) {
            return error("Unauthorized: Admin only");
        }
        string plate = request.car.plate;
        if cars.hasKey(plate) {
            return error("Car with plate already exists");
        }
        cars[plate] = request.car;
        return {plate: plate, message: "Car added successfully"};
    }

    // createUsers: Stream of users from client
    remote function createUsers(stream<User, grpc:Error?> clientStream) returns CreateUsersResponse|error {
        // Note: No auth here, assume initial setup
        int count = 0;
        error? e = clientStream.forEach(function(User user) {
            if users.hasKey(user.user_id) {
                io:println("Duplicate user: " + user.user_id);  // Debug
            } else {
                users[user.user_id] = user;
                count += 1;
            }
        });
        if e is error {
            return e;
        }
        return {message: count.toString() + " users created successfully"};
    }

    // updateCar: Admin updates car
    remote function updateCar(UpdateCarRequest request) returns UpdateCarResponse|error {
        if !self.isAdmin(request.user_id) {
            return error("Unauthorized: Admin only");
        }
        string plate = request.car.plate;
        Car? existing = cars[plate];
        if existing is () {
            return error("Car not found");
        }
        // Update fields (merge)
        cars[plate] = request.car;  // Overwrite with new
        return {message: "Car updated successfully"};
    }

    // removeCar: Admin removes, streams back all cars
    remote function removeCar(RemoveCarRequest request) returns stream<Car, error?>|error {
        if !self.isAdmin(request.user_id) {
            return error("Unauthorized: Admin only");
        }
        string plate = request.plate;
        _ = cars.removeIfHasKey(plate);
        _ = reservations.removeIfHasKey(plate);  // Clean reservations
        // Stream remaining cars
        Car[] carList = from var c in cars
                        select c;
        return carList.toStream();
    }

    // listAvailableCars: Stream available cars, optional filter
    remote function listAvailableCars(ListAvailableCarsRequest request) returns stream<Car, error?>|error {
        // No role check, customers can call
        string filter = request.filter.toLowerAscii();
        Car[] available = from var c in cars
                          where c.status == AVAILABLE
                          where filter == "" || c.make.toLowerAscii().includes(filter) || c.model.toLowerAscii().includes(filter) || c.year.toString().includes(filter)
                          select c;
        return available.toStream();
    }

    // searchCar: Find car by plate if available
    remote function searchCar(SearchCarRequest request) returns SearchCarResponse|error {
        Car? car = cars[request.plate];
        if car is () {
            return {message: "Car not found"};
        }
        if car.status != AVAILABLE {
            return {message: "Car not available"};
        }
        return {car: car, message: "Found"};
    }

    // addToCart: Add item to user's cart
    remote function addToCart(AddToCartRequest request) returns AddToCartResponse|error {
        string userId = request.user_id;
        if !users.hasKey(userId) {
            return error("User not found");
        }
        string plate = request.item.plate;
        if !cars.hasKey(plate) {
            return error("Car not found");
        }
        // Basic checks
        if request.item.start_date >= request.item.end_date {
            return error("Invalid dates");
        }
        CartItem[]? userCart = carts[userId];
        if userCart is () {
            userCart = [];
        }
        userCart.push(request.item);
        carts[userId] = userCart;
        return {message: "Added to cart"};
    }

    // placeReservation: Confirm cart, check overlaps, calculate price
    remote function placeReservation(PlaceReservationRequest request) returns PlaceReservationResponse|error {
        string userId = request.user_id;
        CartItem[]? userCart = carts[userId];
        if userCart is () || userCart.length() == 0 {
            return error("Cart is empty");
        }
        Reservation[] confirmed = [];
        float totalPrice = 0.0;
        foreach CartItem item in userCart {
            string plate = item.plate;
            Car? car = cars[plate];
            if car is () || car.status != AVAILABLE {
                return error("Car " + plate + " not available");
            }
            boolean overlap = check hasOverlap(plate, item.start_date, item.end_date);
            if overlap {
                return error("Date overlap for " + plate);
            }
            int days = check calculateDays(item.start_date, item.end_date);
            float price = <float>days * car.daily_price;
            string resId = uuid:createType1AsString();
            Reservation res = {
                reservation_id: resId,
                user_id: userId,
                plate: plate,
                start_date: item.start_date,
                end_date: item.end_date,
                total_price: price
            };
            Reservation[]? carRes = reservations[plate];
            if carRes is () {
                carRes = [];
            }
            carRes.push(res);
            reservations[plate] = carRes;
            confirmed.push(res);
            totalPrice += price;
            // Mark car unavailable? Assignment doesn't say, assume it becomes unavailable after booking
            car.status = UNAVAILABLE;
            cars[plate] = car;
        }
        // Clear cart
        _ = carts.removeIfHasKey(userId);
        return {reservations: confirmed, total_price: totalPrice, message: "Reservation placed"};
    }

    // listReservations: Admin streams all reservations
    remote function listReservations(ListReservationsRequest request) returns stream<Reservation, error?>|error {
        if !self.isAdmin(request.user_id) {
            return error("Unauthorized: Admin only");
        }
        Reservation[] allRes = [];
        foreach var plateRes in reservations {
            allRes.push(...plateRes);
        }
        return allRes.toStream();
    }
}