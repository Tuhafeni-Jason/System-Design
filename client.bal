import ballerina/grpc;
import ballerina/io;

// Connect to server
CarRentalServiceClient ep = check new ("http://localhost:9090");

public function main() returns error? {
    // Example: Create users (stream)
    grpc:StreamingClient? streamClient = check ep->createUsers();
    if streamClient is grpc:StreamingClient {
        check streamClient->send({user_id: "admin1", name: "Admin One", role: "ADMIN"});
        check streamClient->send({user_id: "cust1", name: "Customer One", role: "CUSTOMER"});
        check streamClient->complete();
        CreateUsersResponse resp = check ep->createUsersComplete(streamClient);
        io:println("Create users response: " + resp.message);
    }

    // Add car (admin)
    AddCarRequest addReq = {
        user_id: "admin1",
        car: {
            make: "Toyota",
            model: "Camry",
            year: 2020,
            daily_price: 50.0,
            mileage: 10000,
            plate: "ABC123",
            status: AVAILABLE
        }
    };
    AddCarResponse addResp = check ep->addCar(addReq);
    io:println("Add car: " + addResp.message);

    // List available cars (customer)
    ListAvailableCarsRequest listReq = {user_id: "cust1", filter: ""};
    stream<Car, grpc:Error?> carStream = check ep->listAvailableCars(listReq);
    error? e = carStream.forEach(function(Car car) {
        io:println("Available car: " + car.make + " " + car.model + " (" + car.plate + ")");
    });
    if e is error {
        io:println("Error listing cars: " + e.message());
    }

    // Add to cart (customer)
    AddToCartRequest cartReq = {
        user_id: "cust1",
        item: {plate: "ABC123", start_date: "2025-10-01", end_date: "2025-10-03"}
    };
    AddToCartResponse cartResp = check ep->addToCart(cartReq);
    io:println("Add to cart: " + cartResp.message);

    // Place reservation
    PlaceReservationRequest resReq = {user_id: "cust1"};
    PlaceReservationResponse resResp = check ep->placeReservation(resReq);
    io:println("Reservation placed, total price: " + resResp.total_price.toString());

    // List reservations (admin)
    ListReservationsRequest resListReq = {user_id: "admin1"};
    stream<Reservation, grpc:Error?> resStream = check ep->listReservations(resListReq);
    error? resE = resStream.forEach(function(Reservation res) {
        io:println("Reservation: " + res.reservation_id + " for " + res.plate);
    });

    // Other ops: You can add more like update, remove, search similarly
}