import ballerina/http;
import ballerina/io;

// Server URL
string serverUrl = "http://localhost:9090/carRental";
http:Client client = check new(serverUrl);

// -------------------- Client Functions --------------------
public function main() returns error? {

    // 1. Add Car (Admin)
    var addCarResp = client->post("/addCar", {
        user_id: "admin1",
        car: {plate: "XYZ999", make: "Honda", model: "Civic", year: 2022, daily_price: 60.0, status: "AVAILABLE"}
    });
    io:println("Add car response: ", addCarResp);

    // 2. List available cars
    Car[] cars = check client->get("/listAvailableCars?filter=");
    foreach var c in cars {
        io:println("Available car: " + c.make + " " + c.model + " (" + c.plate + ")");
    }

    // 3. Add to cart (Customer)
    var cartResp = client->post("/addToCart", {
        user_id: "cust1",
        item: {plate: "ABC123", start_date: "2025-10-01", end_date: "2025-10-03"}
    });
    io:println("Add to cart: ", cartResp);

    // 4. Place reservation
    var resResp = client->post("/placeReservation", {user_id: "cust1"});
    io:println("Place reservation: ", resResp);

    // 5. List reservations
    Reservation[] resList = check client->get("/listReservations?user_id=cust1");
    foreach var r in resList {
        io:println("Reservation: " + r.reservation_id + " for " + r.plate);
    }
}
