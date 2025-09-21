# Manual type definitions for Car Rental System
# These types match the structure in car_rental.proto

# Car details
public type Car record {|
    string id;
    string make;
    string model;
    int year;
    float dailyPrice;
    int mileage;
    CarStatus status;
    string location;
    string createdAt;
|};

# User profile
public type User record {|
    string userId;
    string name;
    string email;
    UserRole role;
    string createdAt;
|};

# Date range for rentals
public type DateRange record {|
    string startDate;
    string endDate;
|};

# Cart item
public type CartItem record {|
    string carId;
    DateRange rentalDates;
    float totalPrice;
|};

# Reservation
public type Reservation record {|
    string reservationId;
    string userId;
    CartItem[] items;
    float totalAmount;
    string status;
    string createdAt;
|};

# Response messages
public type SuccessResponse record {|
    boolean success;
    string message;
    string id;
|};

public type CarList record {|
    Car[] cars;
    int totalCount;
|};

public type CartResponse record {|
    boolean success;
    string message;
    CartItem[] items;
    float totalPrice;
|};

public type ReservationList record {|
    Reservation[] reservations;
    int totalCount;
|};

# Request messages
public type AddCarRequest record {|
    Car car;
    string adminId;
|};

public type UpdateCarRequest record {|
    string carId;
    string adminId;
    string make;
    string model;
    int year;
    float dailyPrice;
    int mileage;
    CarStatus status;
    string location;
|};

public type RemoveCarRequest record {|
    string carId;
    string adminId;
|};

public type ListCarsRequest record {|
    string filterMake;
    int filterYear;
    string customerId;
|};

public type SearchCarRequest record {|
    string carId;
    string customerId;
|};

public type AddToCartRequest record {|
    string carId;
    DateRange rentalDates;
    string customerId;
|};

public type PlaceReservationRequest record {|
    string customerId;
|};

public type ListReservationsRequest record {|
    string userId;
|};

# Enums
public enum CarStatus {
    UNKNOWN_STATUS = "UNKNOWN_STATUS",
    AVAILABLE = "AVAILABLE",
    UNAVAILABLE = "UNAVAILABLE",
    MAINTENANCE = "MAINTENANCE"
}

public enum UserRole {
    UNKNOWN_ROLE = "UNKNOWN_ROLE",
    CUSTOMER = "CUSTOMER",
    ADMIN = "ADMIN"
}