import ballerina/grpc;
import ballerina/io;
import ballerina/log;
import ballerina/uuid;
import ballerina/strings;
import tuhaf.car_rental_system.car_rental as grpc;

# Client class for CarRentalService
client class CarRentalServiceClient {
    private grpc:CarRentalServiceClient clientEndpoint;

    public function init(string url, grpc:ClientConfiguration? config = ()) returns grpc:Error? {
        self.clientEndpoint = check new grpc:CarRentalServiceClient(url, config);
    }

    remote isolated function addCar(grpc:Car car, string adminId) returns grpc:SuccessResponse|grpc:Error {
        grpc:AddCarRequest request = {
            car: car,
            adminId: adminId
        };
        return self.clientEndpoint->addCar(request);
    }

    remote isolated function updateCar(string carId, string adminId, 
        string? make = (), string? model = (), int? year = (), 
        float? dailyPrice = (), int? mileage = (), 
        grpc:CarStatus? status = (), string? location = ()) returns grpc:SuccessResponse|grpc:Error {
        
        grpc:UpdateCarRequest request = {
            carId: carId,
            adminId: adminId,
            make: make ?: "",
            model: model ?: "",
            year: year ?: 0,
            dailyPrice: dailyPrice ?: 0.0,
            mileage: mileage ?: 0,
            status: status ?: grpc:UNKNOWN_STATUS,
            location: location ?: ""
        };
        
        return self.clientEndpoint->updateCar(request);
    }

    remote isolated function removeCar(string carId, string adminId) returns grpc:CarList|grpc:Error {
        grpc:RemoveCarRequest request = {
            carId: carId,
            adminId: adminId
        };
        return self.clientEndpoint->removeCar(request);
    }

    remote isolated function listAvailableCars(string? filterMake = (), int? filterYear = ()) returns grpc:Car[]|grpc:Error {
        grpc:ListCarsRequest request = {
            filterMake: filterMake ?: "",
            filterYear: filterYear ?: 0,
            customerId: "cust1"
        };
        return self.clientEndpoint->listAvailableCars(request);
    }

    remote isolated function searchCar(string carId) returns grpc:Car|grpc:Error {
        grpc:SearchCarRequest request = {
            carId: carId,
            customerId: "cust1"
        };
        return self.clientEndpoint->searchCar(request);
    }

    remote isolated function addToCart(string carId, grpc:DateRange dates) returns grpc:CartResponse|grpc:Error {
        grpc:AddToCartRequest request = {
            carId: carId,
            rentalDates: dates,
            customerId: "cust1"
        };
        return self.clientEndpoint->addToCart(request);
    }

    remote isolated function placeReservation() returns grpc:Reservation|grpc:Error {
        grpc:PlaceReservationRequest request = {
            customerId: "cust1"
        };
        return self.clientEndpoint->placeReservation(request);
    }

    remote isolated function listReservations(string? userId = ()) returns grpc:ReservationList|grpc:Error {
        grpc:ListReservationsRequest request = {
            userId: userId ?: ""
        };
        return self.clientEndpoint->listReservations(request);
    }

    remote isolated function close() returns grpc:Error? {
        return self.clientEndpoint->close();
    }
}

# Interactive CLI Client
public function main() returns error? {
    io:println("=== Car Rental System Client ===");
    io:println("Make sure the server is running on http://localhost:9090");
    io:println("Start it with 'bal run' in another terminal if needed.\n");
    
    CarRentalServiceClient|grpc:Error client = new("http://localhost:9090");
    if (client is grpc:Error) {
        io:println("❌ Error connecting to server: " + client.message());
        io:println("Please start the server first with 'bal run'");
        return;
    }

    io:println("✅ Connected to server successfully!");
    io:println("\n=== Menu ===");
    io:println("1. List Available Cars");
    io:println("2. Search Car by Plate");
    io:println("3. Add Car to Cart");
    io:println("4. Place Reservation");
    io:println("5. View Reservations");
    io:println("6. Admin: Add Car");
    io:println("7. Admin: Update Car Price");
    io:println("8. Admin: Remove Car");
    io:println("9. Exit");

    while (true) {
        string? choice = io:readln("\nEnter choice (1-9): ");
        if (choice is string) {
            match choice.trim() {
                "1" => {
                    io:println("\n=== Available Cars ===");
                    string? filterMake = io:readln("Enter make to filter (or press Enter for all): ");
                    string? filterYearStr = io:readln("Enter year to filter (or press Enter for all): ");
                    
                    int? filterYear = ();
                    if (filterYearStr is string && filterYearStr.trim().length() > 0) {
                        filterYear = check int:fromString(filterYearStr.trim());
                    }
                    
                    grpc:Car[]|grpc:Error cars = client->listAvailableCars(
                        filterMake = filterMake ?: (),
                        filterYear = filterYear
                    );
                    
                    if (cars is grpc:Car[]) {
                        if (cars.length() > 0) {
                            foreach int i, grpc:Car car in cars {
                                io:println(string `${i + 1}. ${car.make} ${car.model} (${car.year})`);
                                io:println(string `   Price: $${car.dailyPrice}/day | Plate: ${car.id}`);
                                io:println(string `   Location: ${car.location} | Mileage: ${car.mileage}km`);
                                io:println();
                            }
                        } else {
                            io:println("No cars available matching your criteria.");
                        }
                    } else {
                        io:println("❌ Error fetching cars: " + cars.message());
                    }
                }
                "2" => {
                    string? plate = io:readln("\nEnter car plate number: ");
                    if (plate is string && plate.trim().length() > 0) {
                        io:println("\n=== Car Search ===");
                        grpc:Car|grpc:Error car = client->searchCar(plate.trim());
                        if (car is grpc:Car) {
                            io:println(string `✅ Found: ${car.make} ${car.model} (${car.year})`);
                            io:println(string `   Price: $${car.dailyPrice}/day`);
                            io:println(string `   Plate: ${car.id} | Location: ${car.location}`);
                            io:println(string `   Mileage: ${car.mileage}km | Status: ${car.status}`);
                        } else {
                            io:println("❌ Car not found or not available: " + car.message());
                        }
                    }
                }
                "3" => {
                    string? plate = io:readln("\nEnter car plate number: ");
                    string? startDate = io:readln("Enter start date (YYYY-MM-DD): ");
                    string? endDate = io:readln("Enter end date (YYYY-MM-DD): ");
                    
                    if (plate is string && startDate is string && endDate is string &&
                        plate.trim().length() > 0 && startDate.trim().length() > 0 && endDate.trim().length() > 0) {
                        
                        grpc:DateRange dates = {
                            startDate: startDate.trim(),
                            endDate: endDate.trim()
                        };
                        
                        grpc:CartResponse|grpc:Error result = client->addToCart(plate.trim(), dates);
                        if (result is grpc:CartResponse) {
                            io:println("✅ Car added to cart successfully!");
                            io:println(string `Total items in cart: ${result.items.length()}`);
                            io:println(string `Cart total: $${result.totalPrice}`);
                        } else {
                            io:println("❌ Error adding to cart: " + result.message());
                        }
                    } else {
                        io:println("❌ Please enter all required fields.");
                    }
                }
                "4" => {
                    io:println("\n=== Placing Reservation ===");
                    grpc:Reservation|grpc:Error reservation = client->placeReservation();
                    if (reservation is grpc:Reservation) {
                        io:println("✅ Reservation placed successfully!");
                        io:println(string `Reservation ID: ${reservation.reservationId}`);
                        io:println(string `Total Amount: $${reservation.totalAmount}`);
                        io:println(string `Status: ${reservation.status}`);
                        io:println(string `Created: ${reservation.createdAt}`);
                        
                        foreach int i, grpc:CartItem item in reservation.items {
                            io:println(string `  ${i + 1}. Car: ${item.carId}`);
                            io:println(string `     Dates: ${item.rentalDates.startDate} to ${item.rentalDates.endDate}`);
                            io:println(string `     Cost: $${item.totalPrice}`);
                        }
                    } else {
                        io:println("❌ Error placing reservation: " + reservation.message());
                    }
                }
                "5" => {
                    io:println("\n=== My Reservations ===");
                    grpc:ReservationList|grpc:Error reservations = client->listReservations();
                    if (reservations is grpc:ReservationList) {
                        if (reservations.reservations.length() > 0) {
                            foreach int i, grpc:Reservation res in reservations.reservations {
                                io:println(string `${i + 1}. Reservation: ${res.reservationId}`);
                                io:println(string `   Total: $${res.totalAmount} | Status: ${res.status}`);
                                io:println(string `   Created: ${res.createdAt}`);
                            }
                        } else {
                            io:println("No reservations found.");
                        }
                    } else {
                        io:println("❌ Error fetching reservations: " + reservations.message());
                    }
                }
                "6" => {
                    io:println("\n=== Admin: Add New Car ===");
                    string? make = io:readln("Enter make (e.g., Toyota): ");
                    string? model = io:readln("Enter model (e.g., Camry): ");
                    string? yearStr = io:readln("Enter year (e.g., 2023): ");
                    string? priceStr = io:readln("Enter daily price (e.g., 50.0): ");
                    string? mileageStr = io:readln("Enter mileage (e.g., 15000): ");
                    string? location = io:readln("Enter location (e.g., Downtown): ");
                    
                    if (make is string && model is string && yearStr is string && 
                        priceStr is string && mileageStr is string && location is string &&
                        make.trim().length() > 0 && model.trim().length() > 0 &&
                        yearStr.trim().length() > 0 && priceStr.trim().length() > 0 &&
                        mileageStr.trim().length() > 0 && location.trim().length() > 0) {
                        
                        grpc:Car newCar = {
                            id: uuid:toString(uuid:createType4AsString()),
                            make: make.trim(),
                            model: model.trim(),
                            year: check int:fromString(yearStr.trim()),
                            dailyPrice: check float:fromString(priceStr.trim()),
                            mileage: check int:fromString(mileageStr.trim()),
                            status: grpc:AVAILABLE,
                            location: location.trim(),
                            createdAt: ""
                        };
                        
                        grpc:SuccessResponse|grpc:Error result = client->addCar(newCar, "admin1");
                        if (result is grpc:SuccessResponse) {
                            io:println("✅ Car added successfully!");
                            io:println(string `ID: ${result.id} | ${newCar.make} ${newCar.model}`);
                        } else {
                            io:println("❌ Error adding car: " + result.message());
                        }
                    } else {
                        io:println("❌ Please enter all required fields.");
                    }
                }
                "7" => {
                    io:println("\n=== Admin: Update Car Price ===");
                    string? carId = io:readln("Enter car ID to update: ");
                    if (carId is string && carId.trim().length() > 0) {
                        string? priceStr = io:readln("Enter new daily price: ");
                        if (priceStr is string && priceStr.trim().length() > 0) {
                            grpc:SuccessResponse|grpc:Error result = client->updateCar(
                                carId.trim(), 
                                "admin1", 
                                dailyPrice = check float:fromString(priceStr.trim())
                            );
                            if (result is grpc:SuccessResponse) {
                                io:println("✅ Car price updated successfully!");
                            } else {
                                io:println("❌ Error updating car: " + result.message());
                            }
                        }
                    }
                }
                "8" => {
                    io:println("\n=== Admin: Remove Car ===");
                    string? carId = io:readln("Enter car ID to remove: ");
                    if (carId is string && carId.trim().length() > 0) {
                        grpc:CarList|grpc:Error result = client->removeCar(carId.trim(), "admin1");
                        if (result is grpc:CarList) {
                            io:println("✅ Car removed successfully!");
                            io:println(string `Remaining cars: ${result.totalCount}`);
                        } else {
                            io:println("❌ Error removing car: " + result.message());
                        }
                    }
                }
                "9" => {
                    io:println("\n👋 Goodbye!");
                    break;
                }
                _ => {
                    io:println("❌ Invalid choice. Please enter 1-9.");
                }
            }
        }
    }

    check client.close();
}