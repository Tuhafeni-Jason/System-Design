CREATE DATABASE IF NOT EXISTS ticketing;
USE ticketing;


CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(20) PRIMARY KEY,
    email VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS routes (
    route_id VARCHAR(20) PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    stops JSON,
    schedule JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


CREATE TABLE IF NOT EXISTS tickets (
    ticket_id VARCHAR(20) PRIMARY KEY,
    user_id VARCHAR(20) NOT NULL,
    type ENUM('single', 'multi', 'pass') NOT NULL,
    status ENUM('CREATED', 'PAID', 'VALIDATED', 'EXPIRED') DEFAULT 'CREATED',
    expiry TIMESTAMP,
    rides_left INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);


CREATE TABLE IF NOT EXISTS payments (
    payment_id VARCHAR(20) PRIMARY KEY,
    ticket_id VARCHAR(20) NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status ENUM('PENDING', 'SUCCESS', 'FAILED') DEFAULT 'PENDING',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ticket_id) REFERENCES tickets(ticket_id) ON DELETE CASCADE


CREATE TABLE IF NOT EXISTS notifications (
    notif_id VARCHAR(20) PRIMARY KEY,
    user_id VARCHAR(20),
    message TEXT,
    type ENUM('DISRUPTION', 'VALIDATION', 'PAYMENT') NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);




CREATE TABLE IF NOT EXISTS routes (route_id VARCHAR(255) PRIMARY KEY, name VARCHAR(255), stops JSON, schedule JSON);
CREATE TABLE IF NOT EXISTS tickets (ticket_id VARCHAR(255) PRIMARY KEY, user_id VARCHAR(255), route_id VARCHAR(255), status VARCHAR(50), created_at TIMESTAMP);
CREATE TABLE IF NOT EXISTS payments (payment_id VARCHAR(255) PRIMARY KEY, ticket_id VARCHAR(255), amount DECIMAL(10,2), status VARCHAR(50));