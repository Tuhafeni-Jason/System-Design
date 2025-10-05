import ballerina/http;
import ballerinax/kafka;
import ballerinax/mysql;
import ballerina/uuid;
import ballerina/sql;
import ballerina/io;

configurable string mysqlHost = "mysql"; 
configurable int mysqlPort = 3306;
configurable string mysqlUser  = "root";
configurable string mysqlPassword = "rootpass";
configurable string mysqlDatabase = "ticketing";

configurable string kafkaBootstrapServers = "kafka:9092";  

type Notification record {
    string notifId;
    string userId;
    string message;
    string? type;
    int timestamp;
};

service /notification on new http:Listener(8084) {
    private final mysql:Client? dbClient;  // Optional for auditing
    private final kafka:Consumer scheduleConsumer;
    private final kafka:Consumer ticketConsumer;

    function init() returns error? {
        // Optional MySQL for auditing
        mysql:ClientConfiguration? config = {
            host: mysqlHost,
            port: mysqlPort,
            user: {user: mysqlUser , password: mysqlPassword},
            database: mysqlDatabase
        };
        self.dbClient = config ? check new (config) : ();

        // Consumer for schedule updates
        kafka:ConsumerConfig scheduleConfig = {
            bootstrapServers: kafkaBootstrap,
            groupId: "notif-group1",
            topics: ["schedule.updates"],
            offsetReset: "earliest",
            autoCommit: true
        };
        self.scheduleConsumer = check new (scheduleConfig);
        check self.scheduleConsumer->attach(self.onScheduleUpdate, messageDispatch = "wait");

        // Consumer for ticket events
        kafka:ConsumerConfig ticketConfig = {
            bootstrapServers: kafkaBootstrap,
            groupId: "notif-group2",
            topics: ["ticket.validated", "ticket.notifications"],
            offsetReset: "earliest",
            autoCommit: true
        };
        self.ticketConsumer = check new (ticketConfig);
        check self.ticketConsumer->attach(self.onTicketEvent, messageDispatch = "wait");
    }

    // Health endpoint
    resource function get .() returns json {
        return {status: "Running", consumers: "Attached"};
    }

    // Callback for schedule updates (e.g., disruptions/delays)
    function onScheduleUpdate(kafka:Consumer consumer, kafka:ConsumerRecord[] records) {
        foreach var rec in records {
            json|error payload = rec.value;
            if payload is json {
                string|error routeId = <string> payload.routeId;
                string|error updateType = <string> payload.updateType;
                string|error message = <string> payload.message;
                if routeId is string && updateType is string && message is string {
                    // Simulate: Get affected users (in prod, query DB or use user-service API)
                    string[] affectedUsers = ["user1", "user2"];  // Placeholder; fetch from DB/events
                    foreach string userId in affectedUsers {
                        string notifMessage = string `Route ${routeId} ${updateType.toLower()}: ${message}`;
                        self.sendNotification(userId, notifMessage, "DISRUPTION");
                    }
                }
            }
        }
        error? commitResult = consumer->commitOffsets(records);
        if commitResult is error {
            io:println("Commit failed: ", commitResult);
        }
    }

    // Callback for ticket events (validation or notifications)
    function onTicketEvent(kafka:Consumer consumer, kafka:ConsumerRecord[] records) {
        foreach var rec in records {
            json|error payload = rec.value;
            if payload is json {
                string|error userId = <string> payload.userId;
                string|error message = <string> payload.message;
                string|error status = <string> payload.status;  // For validated
                if userId is string {
                    string notifMessage = message is string ? message : (status is string ? string `Ticket ${status}` : "Ticket event");
                    self.sendNotification(userId, notifMessage, "VALIDATION");
                }
            }
        }
        error? commitResult = consumer->commitOffsets(records);
        if commitResult is error {
            io:println("Commit failed: ", commitResult);
        }
    }

    // Simulate sending (log to console; in prod: email/SMS API)
    private function sendNotification(string userId, string message, string type) {
        io:println(string `Notification to ${userId} (${type}): ${message}`);
        // Optional: Persist for auditing
        if self.dbClient is mysql:Client {
            string notifId = uuid:createType4AsString();
            int timestamp = time:currentTime();
            check self.dbClient->execute(`INSERT INTO notifications (notif_id, user_id, message, type, timestamp) VALUES (?, ?, ?, ?, ?)`, notifId, userId, message, type, timestamp);
        }
    }

    function 'shutdown'() {
        if self.dbClient is mysql:Client {
            check self.dbClient->close();
        }
    }
}