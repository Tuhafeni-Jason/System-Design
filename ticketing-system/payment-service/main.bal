import ballerina/http;
import ballerinax/mysql;
import ballerinax/kafka;
import ballerina/uuid;
import ballerina/random;
import ballerina/sql;

configurable string mysqlHost = "mysql";  // Docker service name
configurable int mysqlPort = 3306;
configurable string mysqlUser  = "root";
configurable string mysqlPassword = "rootpass";
configurable string mysqlDatabase = "ticketing";

configurable string kafkaBootstrapServers = "kafka:9092";  // Docker service name

type Payment record {
    string paymentId;
    string ticketId;
    float amount;
    string status;
    int timestamp;
};

service /payment on new http:Listener(8083) {
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
            groupId: "payment-group",
            topics: ["ticket.requests"],
            offsetReset: "earliest",
            autoCommit: true
        };
        self.consumer = check new (consConfig);
        check self.consumer->attach(self.onTicketRequest, messageDispatch = "wait");
    }

    // Health endpoint
    resource function get .() returns json {
        return {status: "Running"};
    }

    function onTicketRequest(kafka:Consumer consumer, kafka:ConsumerRecord[] records) {
        foreach var rec in records {
            json|error payload = rec.value;
            if payload is json {
                string|error ticketId = <string> payload.ticketId;
                float|error amount = <float> payload.amount;
                if ticketId is string && amount is float {
                    // Simulate 90% success
                    boolean success = random:coinFlipWithProbability(0.9);
                    string status = success ? "SUCCESS" : "FAILED";
                    string paymentId = uuid:createType4AsString();
                    int timestamp = time:currentTime();
                    check self.dbClient->execute(`INSERT INTO payments (payment_id, ticket_id, amount, status, timestamp) VALUES (?, ?, ?, ?, ?)`, paymentId, ticketId, amount, status, timestamp);
                    json event = {paymentId: paymentId, ticketId: ticketId, status: status};
                    check self.producer->send("payments.processed", {value: event});
                }
            }
        }
        error? commitResult = consumer->commitOffsets(records);
    }

    function 'shutdown'() {
        check self.dbClient->close();
    }
}