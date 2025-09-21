import ballerina/http;
import ballerina/io;
import ballerina/time;
import ballerina/uuid;

// -------------------- Types --------------------
type User record {
    string user_id;
    string name;
    string role; // "ADMIN" or "CUSTOMER"
};

type Car record {
    string plate;
    string make;
    string model;
    int year;
    float daily_price;
    string status; // "AVAILABLE" or "UNAVAILABLE"
};

type Reservation record {
    string reservation_id;
    string user_id;
    string plate;
    string start_date;
    string end_date;
    float total_price;
};

type CartItem record {
    string plate;
    string start_date;
    string end_date;
};

// -------------------- HTTP Requests/Responses --------------------
type AddCarRequest record {
    string user_id;
    Car car;
};
type AddCarResponse record {
    string plate;
    string message;
};

type ListAvailableCarsRequest record {
    string filter;
};

type AddToCartRequest record {
    string user_id;
    CartItem item;
};
type AddToCartResponse record {
    string message;
};

type PlaceReservationRequest record {
    string user_id;
};
type PlaceReservationResponse record {
    Reservation[] reservations;
    float total_price;
    string message;
};

// -------------------- Constants --------------------
const string AVAILABLE = "AVAILABLE";
const string UNAVAILABLE = "UNAVAILABLE";

// -------------------- Storage --------------------
map<User> users = {};
map<Car> cars = {};
map<Reservation[]> resByCar = {};
map<Reservation[]> resByUser = {};
map<CartItem[]> carts = {};

// -------------------- Startup sample data --------------------
init {
    users["admin1"] = {user_id: "admin1", name: "Admin", role: "ADMIN"};
    users["cust1"] = {user_id: "cust1", name: "Customer", role: "CUSTOMER"};
    cars["ABC123"] = {plate: "ABC123", make: "Toyota", model: "Camry", year: 2023, daily_price: 50.0, status: AVAILABLE};
    io:println("Server started with sample data!");
}

// -------------------- Helper Functions --------------------
function isAdmin(string id) returns boolean {
    User? u = users.get(id);
    return u != null && u.role == "ADMIN";
}

function parseDate(string d) returns time:Utc|error {
    string[] p = d.split("-");
    if p.length() != 3 {
        return error("Bad date: use YYYY-MM-DD");
    }
    int y = check int:fromString(p[0]);
    int m = check int:fromString(p[1]);
    int day = check int:fromString(p[2]);
    return time:createTime(y, m, day, 0, 0, 0);
}

function overlap(string plate, string start, string end) returns boolean|error {
    Reservation[]? r = resByCar.get(plate);
    if r == null {
        return false;
    }
    time:Utc s = check parseDate(start);
    time:Utc e = check parseDate(end);
    int sTime = time:toUnixTime(s);
    int eTime = time:toUnixTime(e);
    foreach Reservation res in r {
        time:Utc rs = check parseDate(res.start_date);
        time:Utc re = check parseDate(res.end_date);
        int rsTime = time:toUnixTime(rs);
        int reTime = time:toUnixTime(re);
        if !(eTime < rsTime || sTime > reTime) {
            return true;
        }
    }
    return false;
}

function days(string start, string end) returns int|error {
    time:Utc s = check parseDate(start);
    time:Utc e = check parseDate(end);
    int sTime = time:toUnixTime(s);
    int eTime = time:toUnixTime(e);
    if eTime <= sTime {
        return error("End before start");
    }
    return ((eTime - sTime) / 86400) max 1;
}

// -------------------- HTTP Service --------------------
listener http:Listener ep = new(9090);

service /carRental on ep {

    // Add Car (Admin)
    resource function post addCar(AddCarRequest req) returns AddCarResponse|error {
        if !isAdmin(req.user_id) {
            return error("Admin only");
        }
        string p = req.car.plate;
        if cars.hasKey(p) {
            return error("Car exists");
        }
        cars[p] = req.car;
        return {plate: p, message: "Added car"};
    }

    // List available cars
    resource function get listAvailableCars(@http:Query string filter) returns Car[]|error {
        string f = filter.toLowerAscii();
        Car[] a = from Car c in cars
                  where c.status == AVAILABLE
                  where f == "" || c.make.toLowerAscii().includes(f) || c.model.toLowerAscii().includes(f)
                  select c;
        return a;
    }

    // Add to cart
    resource function post addToCart(AddToCartRequest req) returns AddToCartResponse|error {
        if !users.hasKey(req.user_id) {
            return error("User not found");
        }
        string p = req.item.plate;
        Car? c = cars.get(p);
        if c == null || c.status != AVAILABLE {
            return error("Car unavailable");
        }
        check parseDate(req.item.start_date);
        check parseDate(req.item.end_date);
        if check overlap(p, req.item.start_date, req.item.end_date) {
            return error("Date overlap");
        }
        CartItem[]? cart = carts.get(req.user_id);
        if cart == null {
            cart = [];
        }
        cart.push(req.item);
        carts[req.user_id] = cart;
        return {message: "Added to cart"};
    }

    // Place reservation
    resource function post placeReservation(PlaceReservationRequest req) returns PlaceReservationResponse|error {
        if !users.hasKey(req.user_id) {
            return error("User not found");
        }
        CartItem[]? cart = carts.get(req.user_id);
        if cart == null || cart.length() == 0 {
            return {reservations: [], total_price: 0.0, message: "Empty cart"};
        }
        Reservation[] newRes = [];
        float total = 0.0;
        foreach CartItem item in cart {
            string p = item.plate;
            Car? c = cars.get(p);
            if c == null || c.status != AVAILABLE {
                return error("Car issue: " + p);
            }
            if check overlap(p, item.start_date, item.end_date) {
                return error("Overlap: " + p);
            }
            int d = check days(item.start_date, item.end_date);
            float price = c.daily_price * <float> d;
            string id = check uuid:toString(uuid:createType4());
            Reservation r = {reservation_id: id, user_id: req.user_id, plate: p, start_date: item.start_date, end_date: item.end_date, total_price: price};
            newRes.push(r);
            total += price;

            // Save to storage
            Reservation[]? byCar = resByCar.get(p);
            if byCar == null {
                byCar = [];
            }
            byCar.push(r);
            resByCar[p] = byCar;

            Reservation[]? byUser = resByUser.get(req.user_id);
            if byUser == null {
                byUser = [];
            }
            byUser.push(r);
            resByUser[req.user_id] = byUser;

            // Mark car unavailable
            c.status = UNAVAILABLE;
            cars[p] = c;
        }
        carts.remove(req.user_id);
        return {reservations: newRes, total_price: total, message: "Reserved!"};
    }

    // List user reservations
    resource function get listReservations(@http:Query string user_id) returns Reservation[]|error {
        if !users.hasKey(user_id) {
            return error("User not found");
        }
        Reservation[]? r = resByUser.get(user_id);
        if r == null {
            r = [];
        }
        return r;
    }
}
