import ballerina/http;
import ballerinax/mysql;
import ballerinax/kafka;
import ballerina/time;
import ballerina/uuid;
import ballerina/jwt;
import ballerina/lang.'array;
import ballerina/lang.runtime;

configurable string jwtSecret = "A_VERY_STRONG_SECRET_KEY_FOR_JWT_SIGNING";

configurable string mysqlHost = "mysql";
configurable int mysqlPort = 3306;
configurable string mysqlUser = "root";
configurable string mysqlPassword = "rootpass";
configurable string mysqlDatabase = "ticketing";

configurable string kafkaBootstrapServers = "kafka:29092";

type DisruptionInput record {
    string 'type;
    string message;
};

type RouteInput record {
    string name;
    string stops;
};

type Report record {
    int totalTickets;
    int paidTickets;
    decimal? totalRevenue;
    decimal? avgTicketPrice;
};

type TrafficReport record {
    string routeId;
    int uniquePassengers;
    int totalValidations;
};

final mysql:Client dbClient;
final kafka:Producer kafkaProducer;

function init() returns error? {
    mysql:ClientConfiguration dbConfig = {
        host: mysqlHost,
        port: mysqlPort,
        user: mysqlUser,
        password: mysqlPassword,
        database: mysqlDatabase
    };
    dbClient = check new (dbConfig);

    kafka:ProducerConfiguration kafkaConfig = {
        bootstrapServers: kafkaBootstrapServers
    };
    kafkaProducer = check new (kafkaConfig);

    runtime:onGracefulStop(gracefulShutdown);
}

function gracefulShutdown() returns error? {
    check dbClient->close();
    check kafkaProducer->close();
}

service /admin on new http:Listener(8085) {

    private final jwt:Validator validator;

    function init() returns error? {
        jwt:ValidatorConfig validatorConfig = {
            signatureConfig: {
                config: {
                    secret: jwtSecret,
                    algorithm: jwt:HS256
                }
            }
        };
        self.validator = check new (validatorConfig);
    }

    isolated function isAdmin(string authorization) returns error? {
        string token = authorization.trim().split(" ");
        jwt:Payload tokenPayload = check self.validator->validate(token);

        var role = tokenPayload["role"];
        if!(role is string) |

| role!= "admin" {
            return error http:ForbiddenError("Forbidden: Must be an admin user");
        }
    }

    resource function post disruptions/[string routeId](@http:Header string authorization, DisruptionInput input) returns json|error {
        check self.isAdmin(authorization);

        json event = {
            routeId: routeId,
            updateType: input.'type,
            message: input.message
        };
        string key = routeId;
        check kafkaProducer->send({
            topic: "schedule.updates",
            key: key,
            value: event
        });
        return {status: "Disruption published", route: routeId};
    }

    resource function get reports/sales(@http:Header string authorization, string? 'from, string? to) returns Report|error {
        check self.isAdmin(authorization);

        time:Civil fromDate = check 'from is string? time:civilFromString('from + "T00:00:00Z") : time:civilFromString("1970-01-01T00:00:00Z");
        time:Civil toDate = check to is string? time:civilFromString(to + "T23:59:59Z") : time:utcToCivil(time:utcNow());

        sql:ParameterizedQuery query = `
            SELECT
                COUNT(t.ticket_id) AS totalTickets,
                SUM(CASE WHEN p.status = 'SUCCESS' THEN 1 ELSE 0 END) AS paidTickets,
                SUM(CASE WHEN p.status = 'SUCCESS' THEN p.amount END) AS totalRevenue,
                AVG(CASE WHEN p.status = 'SUCCESS' THEN p.amount END) AS avgTicketPrice
            FROM tickets t
            LEFT JOIN payments p ON t.ticket_id = p.ticket_id
            WHERE t.created_at BETWEEN ${fromDate} AND ${toDate}
        `;
        return dbClient->queryRow(query);
    }

    resource function get reports/traffic/[string routeId](@http:Header string authorization) returns TrafficReport|error {
        check self.isAdmin(authorization);

        sql:ParameterizedQuery query = `
            SELECT
                t.route_id AS routeId,
                COUNT(DISTINCT user_id) AS uniquePassengers,
                COUNT(ticket_id) AS totalValidations
            FROM tickets t
            WHERE t.route_id = ${routeId} AND t.status = 'VALIDATED'
            GROUP BY t.route_id
        `;
        return dbClient->queryRow(query);
    }

    resource function post routes(@http:Header string authorization, RouteInput input) returns json|error {
        check self.isAdmin(authorization);

        string routeId = uuid:createType4AsString();
        sql:ParameterizedQuery query = `
            INSERT INTO routes (route_id, name, stops, schedule_data)
            VALUES (${routeId}, ${input.name}, ${input.stops.toJsonString()}, '{}')
        `;
        _ = check dbClient->execute(query);

        json newRouteEvent = {routeId: routeId, name: input.name, status: "CREATED"};
        check kafkaProducer->send({
            topic: "schedule.updates",
            key: routeId,
            value: newRouteEvent
        });

        return {routeId: routeId, status: "Created"};
    }
}