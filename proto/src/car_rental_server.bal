import ballerina/grpc;
import ballerina/io;
import proto.src.types; // import types

// In-memory stores
map<Car> cars = {};
map<Reservation> reservations = {};
map<User> users = {};

service "CarRentalService" on new grpc:Listener(9090) {

    remote function AddCar(AddCarRequest req) returns SuccessResponse|error {
        cars[req.car.id] = req.car;
        io:println("🚗 Added Car: ", req.car);
        return { success: true, message: "Car added successfully", id: req.car.id };
    }

    remote function UpdateCar(UpdateCarRequest req) returns SuccessResponse|error {
        if cars.hasKey(req.carId) {
            Car updatedCar = {
                id: req.carId,
                make: req.make,
                model: req.model,
                year: req.year,
                dailyPrice: req.dailyPrice,
                mileage: req.mileage,
                status: req.status,
                location: req.location,
                createdAt: "2025-09-21"
            };
            cars[req.carId] = updatedCar;
            return { success: true, message: "Car updated", id: req.carId };
        }
        return { success: false, message: "Car not found", id: req.carId };
    }

    remote function RemoveCar(RemoveCarRequest req) returns SuccessResponse|error {
        if cars.hasKey(req.carId) {
            cars.remove(req.carId);
            return { success: true, message: "Car removed", id: req.carId };
        }
        return { success: false, message: "Car not found", id: req.carId };
    }

    remote function SearchCar(SearchCarRequest req) returns Car|error {
        if cars.hasKey(req.carId) {
            return cars[req.carId];
        }
        return error("Car not found");
    }

    remote function PlaceReservation(PlaceReservationRequest req) returns Reservation|error {
        string resId = "RES-" + req.customerId;
        Reservation res = {
            reservationId: resId,
            userId: req.customerId,
            items: [],
            totalAmount: 0.0,
            status: "CONFIRMED",
            createdAt: "2025-09-21"
        };
        reservations[resId] = res;
        return res;
    }

    remote function ListReservations(ListReservationsRequest req) returns ReservationList|error {
        Reservation[] resList = [];
        foreach var [_, res] in reservations.entries() {
            if res.userId == req.userId {
                resList.push(res);
            }
        }
        return { reservations: resList, totalCount: resList.length() };
    }
}
