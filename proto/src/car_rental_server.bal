import ballerina/grpc;
import ballerina/log;
import ballerina/uuid;
import ballerina/io;
import ballerina/strings;
import ballerina/time;
import ballerina/runtime;
import tuhaf.car_rental_system.car_rental as grpc;  // Import generated types

# Service class for business logic
service class CarRentalServiceLogic {
    private map<grpc:Car> cars = {};
    private map<grpc:User> users = {};
    private map<map<grpc:CartItem>> customerCarts = {};
    private map<grpc:Reservation> reservations = {};

    isolated function init() {
        log:printInfo("Initializing Car Rental System with sample data...");
        
        // Add sample cars
        grpc:Car toyota = {
            id: "ABC123",
            make: "Toyota",
            model: "Camry",
            year: 2022,
            dailyPrice: 50.0,
            mileage: 15000,
            status: grpc:AVAILABLE,
            location: "Downtown",
            createdAt: self.getCurrentTimeString()
        };
        grpc:Car honda = {
            id: "XYZ789",
            make: "Honda",
            model: "Civic",
            year: 2023,
            dailyPrice: 45.0,
            mileage: 8000,
            status: grpc:AVAILABLE,
            location: "Airport",
            createdAt: self.getCurrentTimeString()
        };
        self.cars.put(toyota.id, toyota);
        self.cars.put(honda.id, honda);

        // Add sample users
        grpc:User admin = {
            userId: "admin1",
            name: "Admin User",
            email: "admin@company.com",
            role: grpc:ADMIN,
            createdAt: self.getCurrentTimeString()
        };
        grpc:User customer = {
            userId: "cust1",
            name: "John Doe",
            email: "john@example.com",
            role: grpc:CUSTOMER,
            createdAt: self.getCurrentTimeString()
        };
        self.users.put(admin.userId, admin);
        self.users.put(customer.userId, customer);

        log:printInfo("Sample data initialized. Cars: " + self.cars.length().toString() + ", Users: " + self.users.length().toString());
    }

    remote isolated function addCar(grpc:AddCarRequest|error req) returns grpc:SuccessResponse|error {
        if (req is grpc:AddCarRequest) {
            log:printInfo("Add car request from: " + req.adminId);
            
            if (!self.isAdmin(req.adminId)) {
                return error("Unauthorized: Admin access required");
            }

            string carId = req.car.id.length() > 0 ? req.car.id : uuid:toString(uuid:createType4AsString());
            grpc:Car newCar = {
                ...req.car,
                id: carId,
                createdAt: self.getCurrentTimeString()
            };

            self.cars.put(carId, newCar);
            log:printInfo("Car added: " + carId + " - " + newCar.make + " " + newCar.model);

            return {
                success: true,
                message: "Car added successfully",
                id: carId
            };
        }
        return error("Invalid request");
    }

    remote isolated function updateCar(grpc:UpdateCarRequest|error req) returns grpc:SuccessResponse|error {
        if (req is grpc:UpdateCarRequest) {
            log:printInfo("Update car request for: " + req.carId);
            
            if (!self.isAdmin(req.adminId)) {
                return error("Unauthorized: Admin access required");
            }

            grpc:Car? existingCar = self.cars.get(req.carId);
            if (existingCar == ()) {
                return error("Car not found: " + req.carId);
            }

            grpc:Car updatedCar = {
                ...existingCar,
                make: req.make.length() > 0 ? req.make : existingCar.make,
                model: req.model.length() > 0 ? req.model : existingCar.model,
                year: req.year > 0 ? req.year : existingCar.year,
                dailyPrice: req.dailyPrice > 0 ? req.dailyPrice : existingCar.dailyPrice,
                mileage: req.mileage >= 0 ? req.mileage : existingCar.mileage,
                status: req.status != grpc:UNKNOWN_STATUS ? req.status : existingCar.status,
                location: req.location.length() > 0 ? req.location : existingCar.location
            };

            self.cars.put(req.carId, updatedCar);
            log:printInfo("Car updated: " + req.carId);

            return {
                success: true,
                message: "Car updated successfully"
            };
        }
        return error("Invalid request");
    }

    remote isolated function removeCar(grpc:RemoveCarRequest|error req) returns grpc:CarList|error {
        if (req is grpc:RemoveCarRequest) {
            log:printInfo("Remove car request for: " + req.carId);
            
            if (!self.isAdmin(req.adminId)) {
                return error("Unauthorized: Admin access required");
            }

            _ = self.cars.remove(req.carId);
            log:printInfo("Car removed: " + req.carId);

            return {
                cars: self.getAllCars(),
                totalCount: self.cars.length()
            };
        }
        return error("Invalid request");
    }

    remote isolated function listAvailableCars(grpc:ListCarsRequest|error req) returns grpc:Car[]|error {
        if (req is grpc:ListCarsRequest) {
            log:printInfo("List available cars for customer: " + req.customerId);
            
            grpc:Car[] allCars = self.getAllCars();
            grpc:Car[] result = [];

            foreach grpc:Car car in allCars {
                if (req.filterMake.length() > 0 && !strings:contains(car.make.toLower(), req.filterMake.toLower())) {
                    continue;
                }

                if (req.filterYear > 0 && car.year != req.filterYear) {
                    continue;
                }

                if (car.status == grpc:AVAILABLE) {
                    result.push(car);
                }
            }

            log:printInfo("Returning " + result.length().toString() + " available cars");
            return result;
        }
        return error("Invalid request");
    }

    remote isolated function searchCar(grpc:SearchCarRequest|error req) returns grpc:Car|error {
        if (req is grpc:SearchCarRequest) {
            log:printInfo("Search car: " + req.carId + " for customer: " + req.customerId);
            
            grpc:Car? foundCar = self.cars.get(req.carId);
            if (foundCar == ()) {
                return error("Car not found: " + req.carId);
            }

            if (foundCar.status != grpc:AVAILABLE) {
                return error("Car is not available: " + foundCar.status);
            }

            return foundCar;
        }
        return error("Invalid request");
    }

    remote isolated function addToCart(grpc:AddToCartRequest|error req) returns grpc:CartResponse|error {
        if (req is grpc:AddToCartRequest) {
            log:printInfo("Add to cart: " + req.carId + " for customer: " + req.customerId);
            
            grpc:User? user = self.users.get(req.customerId);
            if (user == () || user.role != grpc:CUSTOMER) {
                return error("Customer not found or unauthorized");
            }

            grpc:Car? car = self.cars.get(req.carId);
            if (car == ()) {
                return error("Car not found: " + req.carId);
            }

            if (car.status != grpc:AVAILABLE) {
                return error("Car is not available: " + car.status);
            }

            if (!self.isValidDateRange(req.rentalDates)) {
                return error("Invalid rental dates");
            }

            int days = self.calculateDays(req.rentalDates);
            float price = <float>days * car.dailyPrice;

            grpc:CartItem cartItem = {
                carId: req.carId,
                rentalDates: req.rentalDates,
                totalPrice: price
            };

            map<grpc:CartItem> cart = self.customerCarts.get(req.customerId) ?: {};
            cart.put(req.carId, cartItem);
            self.customerCarts.put(req.customerId, cart);

            return {
                success: true,
                message: "Car added to cart successfully",
                items: self.getCustomerCartItems(req.customerId),
                totalPrice: self.getCustomerCartTotal(req.customerId)
            };
        }
        return error("Invalid request");
    }

    remote isolated function placeReservation(grpc:PlaceReservationRequest|error req) returns grpc:Reservation|error {
        if (req is grpc:PlaceReservationRequest) {
            log:printInfo("Place reservation for customer: " + req.customerId);
            
            grpc:User? user = self.users.get(req.customerId);
            if (user == () || user.role != grpc:CUSTOMER) {
                return error("Customer not found or unauthorized");
            }

            map<grpc:CartItem> cart = self.customerCarts.get(req.customerId) ?: {};
            if (cart.length() == 0) {
                return error("Cart is empty");
            }

            string reservationId = uuid:toString(uuid:createType4AsString());
            float totalAmount = 0.0;

            grpc:CartItem[] reservationItems = [];
            foreach grpc:CartItem item in cart.values() {
                reservationItems.push(item);
                totalAmount += item.totalPrice;
            }

            grpc:Reservation reservation = {
                reservationId: reservationId,
                userId: req.customerId,
                items: reservationItems,
                totalAmount: totalAmount,
                status: "CONFIRMED",
                createdAt: self.getCurrentTimeString()
            };

            self.reservations.put(reservationId, reservation);
            self.customerCarts.remove(req.customerId);

            foreach grpc:CartItem item in reservationItems {
                grpc:Car? car = self.cars.get(item.carId);
                if (car is grpc:Car) {
                    car.status = grpc:UNAVAILABLE;
                    self.cars.put(item.carId, car);
                }
            }

            log:printInfo("Reservation created: " + reservationId + " - Total: $" + totalAmount.toString());
            return reservation;
        }
        return error("Invalid request");
    }

    remote isolated function listReservations(grpc:ListReservationsRequest|error req) returns grpc:ReservationList|error {
        if (req is grpc:ListReservationsRequest) {
            log:printInfo("List reservations for user: " + req.userId);
            
            grpc:Reservation[] userReservations = [];
            foreach [string, grpc:Reservation] [id, res] in self.reservations.entries() {
                if (req.userId.length() == 0 || res.userId == req.userId) {
                    userReservations.push(res);
                }
            }

            return {
                reservations: userReservations,
                totalCount: userReservations.length()
            };
        }
        return error("Invalid request");
    }

    isolated function isAdmin(string userId) returns boolean {
        grpc:User? user = self.users.get(userId);
        return user is grpc:User && user.role == grpc:ADMIN;
    }

    isolated function getAllCars() returns grpc:Car[] {
        grpc:Car[] result = [];
        foreach [string, grpc:Car] [id, car] in self.cars.entries() {
            result.push(car);
        }
        return result;
    }

    isolated function isValidDateRange(grpc:DateRange dates) returns boolean {
        if (dates.startDate.length() == 0 || dates.endDate.length() == 0) {
            return false;
        }
        return dates.startDate <= dates.endDate;
    }

    isolated function calculateDays(grpc:DateRange dates) returns int {
        string[] startParts = strings:split(dates.startDate, "-");
        string[] endParts = strings:split(dates.endDate, "-");
        
        if (startParts.length() >= 3 && endParts.length() >= 3) {
            int|error startDay = int:fromString(startParts[2]);
            int|error endDay = int:fromString(endParts[2]);
            if (startDay is int && endDay is int) {
                return endDay - startDay + 1;
            }
        }
        return 1;
    }

    isolated function getCustomerCartItems(string customerId) returns grpc:CartItem[] {
        map<grpc:CartItem> cart = self.customerCarts.get(customerId) ?: {};
        grpc:CartItem[] items = [];
        foreach grpc:CartItem item in cart.values() {
            items.push(item);
        }
        return items;
    }

    isolated function getCustomerCartTotal(string customerId) returns float {
        map<grpc:CartItem> cart = self.customerCarts.get(customerId) ?: {};
        float total = 0.0;
        foreach grpc:CartItem item in cart.values() {
            total += item.totalPrice;
        }
        return total;
    }

    isolated function getCurrentTimeString() returns string {
        time:CivilTime civilTime = time:now();
        return string `2025-${civilTime.month:02d}-${civilTime.day:02d} ${civilTime.hour:02d}:${civilTime.minute:02d}:${civilTime.second:02d}`;
    }
}

# gRPC Service implementation using generated interface
service CarRentalService on new grpc:Listener(9090) {
    private CarRentalServiceLogic serviceLogic;

    function init() {
        self.serviceLogic = new;
        self.serviceLogic.init();
    }

    # AddCar RPC
    resource function get addCar(grpc:AddCarRequest req) returns grpc:SuccessResponse|error {
        return self.serviceLogic->addCar(req);
    }

    # UpdateCar RPC
    resource function get updateCar(grpc:UpdateCarRequest req) returns grpc:SuccessResponse|error {
        return self.serviceLogic->updateCar(req);
    }

    # RemoveCar RPC
    resource function get removeCar(grpc:RemoveCarRequest req) returns grpc:CarList|error {
        return self.serviceLogic->removeCar(req);
    }

    # ListAvailableCars RPC
    resource function get listAvailableCars(grpc:ListCarsRequest req) returns grpc:Car[]|error {
        return self.serviceLogic->listAvailableCars(req);
    }

    # SearchCar RPC
    resource function get searchCar(grpc:SearchCarRequest req) returns grpc:Car|error {
        return self.serviceLogic->searchCar(req);
    }

    # AddToCart RPC
    resource function get addToCart(grpc:AddToCartRequest req) returns grpc:CartResponse|error {
        return self.serviceLogic->addToCart(req);
    }

    # PlaceReservation RPC
    resource function get placeReservation(grpc:PlaceReservationRequest req) returns grpc:Reservation|error {
        return self.serviceLogic->placeReservation(req);
    }

    # ListReservations RPC
    resource function get listReservations(grpc:ListReservationsRequest req) returns grpc:ReservationList|error {
        return self.serviceLogic->listReservations(req);
    }
}