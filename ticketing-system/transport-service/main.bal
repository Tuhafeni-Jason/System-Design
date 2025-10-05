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
type Route record {
    string routeId;
    string name;
    json stops;  // JSON for array
};

type RouteInput record {
    string name;
    string[] stops;
};

type ScheduleUpdate record {
    string routeId;
    string type;  // "DELAY"|"CANCEL"
    string message;
};

service /transport on new http:Listener(8081) {
    private final mysql:Client dbClient;
    private final kafka:Producer kafkaProducer;

    function init() returns error? {
        mysql:ClientConfiguration config = {
            host: mysqlHost, port: mysqlPort, user: {user: mysqlUser , password: mysqlPassword}, database: mysqlDatabase
        };
        self.dbClient = check new (config);
        kafka:ProducerConfig kafkaConfig = {bootstrapServers: kafkaBootstrap};
        self.kafkaProducer = check new (kafkaConfig);
    }

    resource function post routes(RouteInput input) returns Route|http:InternalError {
        string routeId = uuid:createType4AsString();
        json stopsJson = input.stops.toJson();
        sql:ExecutionResult result = check self.dbClient->execute(`INSERT INTO routes (route_id, name, stops) VALUES (?, ?, ?)`, routeId, input.name, stopsJson);
        return {routeId: routeId, name: input.name, stops: stopsJson};
    }

    resource function post updates(ScheduleUpdate update) returns json {
        json event = {routeId: update.routeId, updateType: update.type, message: update.message};
        error? sendResult = self.kafkaProducer->send("schedule.updates", {value: event});
        if sendResult is error {
            return {error: "Failed to publish"};
        }
        return {status: "Published"};
    }

    function 'shutdown'() {
        check self.dbClient->close();
    }
}