import ballerina/log;
import ballerina/io;
import tuhaf.car_rental_system.car_rental as grpc;

public function main() returns error? {
    log:printInfo("=== Starting Car Rental System Server ===");
    io:println("🚗 Car Rental gRPC Server");
    io:println("📡 Listening on http://localhost:9090");
    io:println("💡 Start the client with 'bal run car_rental_client'");
    io:println("⏹️  Press Ctrl+C to stop the server\n");
    
    // Create and start the gRPC server
    grpc:Listener grpcListener = new(9090);
    CarRentalService service = new;
    
    check grpcListener.attach(service);
    log:printInfo("✅ Car Rental gRPC Server started successfully");
    
    // Keep the server running
    io:println("Server is running. Waiting for requests...");
    while (true) {
        runtime:sleep(1000);
    }
}