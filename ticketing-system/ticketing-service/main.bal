import ballerina/http;
import ballerinax/mysql;
import ballerinax/kafka;
import ballerina/uuid;
import ballerina/sql;
configurable string mysqlHost = "mysql";  // Docker service name
configurable int mysqlPort = 3306;
configurable string mysqlUser  = "root";
configurable string mysqlPassword = "rootpass";
configurable string mysqlDatabase = "ticketing";

configurable string kafkaBootstrapServers = "kafka:9092";  // Docker service name
type TicketRequest record {
    string userId;
    string type;
    int rides;
    float amount;
};

type ValidationResult record {
    boolean success;
};

type Ticket record {
    string ticketId;
    string userId;
    string type;
    string status;
    int ridesLeft;
};

service /ticketing on new http:Listener(8082) {
    private final mysql:Client dbClient;
    private final kafka:Producer producer;
    private final kafka:Consumer consumer;

    function init() returns error? {
        mysql:ClientConfiguration config = {
            host: mysqlHost, port: mysqlPort, user: {user: mysqlUser , password: mysqlPassword}, database: mysqlDatabase
        };
        self.dbClient = check new (config);
        kafka:ProducerConfig prodConfig = {bootstrapServers: kafkaBootstrap};
        self.producer = check new (prodConfig);
        kafka:ConsumerConfig consConfig = {
            bootstrapServers: kafkaBootstrap,
            groupId: "ticketing-group",
            topics: ["payments.processed"],
            offsetReset: "earliest",
            autoCommit: true
        };
        self.consumer = check new (consConfig);
        check self.consumer->attach(self.onPaymentProcessed, messageDispatch = "wait");
    }

    resource function post purchase(TicketRequest req) returns string|http:InternalError {
        string ticketId = uuid:createType4AsString();
        sql:ExecutionResult result = check self.dbClient->execute(`INSERT INTO tickets (ticket_id, user_id, type, rides_left) VALUES (?, ?, ?, ?)`, ticketId, req.userId, req.type, req.rides);
        json event = {ticketId: ticketId, userId: req.userId, type: req.type, amount: req.amount};
        error? sendResult = self.producer->send("ticket.requests", {value: event});
        if sendResult is error {
            return http:InternalError("Failed to request payment");
        }
        return ticketId;
    }

    resource function post validate/[string ticketId]() returns ValidationResult|http:BadRequest {
        Ticket|sql:Error ticket = self.dbClient->queryRow(`SELECT * FROM tickets WHERE ticket_id = ? AND status = 'PAID'`, ticketId);
        if ticket is sql:NoRowsError || ticket is error {
            return http:BadRequest("Invalid or unpaid ticket");
        }
        // Update status and decrement rides
        check self.dbClient->execute(`UPDATE tickets SET status = 'VALIDATED', rides_left = rides_left - 1 WHERE ticket_id = ?`, ticketId);
        // Publish events
        json validatedEvent = {ticketId: ticketId, userId: ticket.userId, status: "VALIDATED"};
        check self.producer->send("ticket.validated", {value: validatedEvent});
        json notifEvent = {userId: ticket.userId, message: "Ticket validated successfully"};
        check self.producer->send("ticket.notifications", {value: notifEvent});
        return {success: true};
    }

    function onPaymentProcessed(kafka:Consumer consumer, kafka:ConsumerRecord[] records) {
        foreach var rec in records {
            json|error payload = rec.value;
            if payload is json {
                string|error ticketId = <string> payload.ticketId;
                string|error status = <string> payload.status;
                if ticketId is string && status is string && status == "SUCCESS" {
                    check self.dbClient->execute(`UPDATE tickets SET status = 'PAID' WHERE ticket_id = ?`, ticketId);
                }
            }
        }
        error? commitResult = consumer->commitOffsets(records);
    }

    function 'shutdown'() {
        check self.dbClient->close();
    }
}