import ballerina/http;
import ballerinax/mysql;
import ballerinax/jwt;
import ballerina/uuid;
import ballerina/sql;

configurable string mysqlHost = "mysql";  
configurable int mysqlPort = 3306;
configurable string mysqlUser  = "root";
configurable string mysqlPassword = "rootpass";
configurable string mysqlDatabase = "ticketing";

configurable string kafkaBootstrapServers = "kafka:9092";  

type User record {
    string userId;
    string email;
    string passwordHash;
};

type UserInput record {
    string email;
    string password;
};

type LoginInput record {
    string email;
    string password;
};

type AccessToken record {
    string accessToken;
};

type Ticket record {
    string ticketId;
    string status;
    string types;
};

service /passenger on new http:Listener(8080) {
    private final mysql:Client dbClient;
    private final jwt:JWTIssuer issuer;

    function init() returns error? {
        mysql:ClientConfiguration config = {
            host: mysqlHost,
            port: mysqlPort,
            user: {user: mysqlUser , password: mysqlPassword},
            database: mysqlDatabase
        };
        self.dbClient = check new (config);
        self.issuer = new (jwtSecret);
    }

    resource function post register(UserInput userInput) returns User|http:BadRequest|http:InternalError {
        string userId = uuid:createType4AsString();
        sql:ExecutionResult result = check self.dbClient->execute(`INSERT INTO users (user_id, email, password_hash) VALUES (?, ?, ?)`, userId, userInput.email, userInput.password);
        if result.updatedRowCount == 0 {
            return http:BadRequest("User  already exists");
        }
        User newUser  = {userId: userId, email: userInput.email, passwordHash: userInput.password};
        return newUser ;
    }

    resource function post login(LoginInput login) returns AccessToken|http:Unauthorized {
        User user = check self.getUser ByEmail(login.email);
        if user.passwordHash != login.password {  // Hash in prod
            return http:Unauthorized("Invalid credentials");
        }
        string|error token = self.issuer->issue({userId: user.userId});
        if token is error {
            return http:InternalError("Token generation failed");
        }
        return {accessToken: token};
    }

    resource function get tickets/[string userId]() returns Ticket[]|http:NotFound {
        Ticket[] tickets = [];
        stream<Ticket, error?> result = self.dbClient->query(`SELECT ticket_id, status, type FROM tickets WHERE user_id = ?`, userId);
        check result.forEach(function (Ticket ticket) {
            tickets.push(ticket);
        });
        check result.close();
        if tickets.length() == 0 {
            return http:NotFound("No tickets found");
        }
        return tickets;
    }

    private function getUser ByEmail(string email) returns User|http:NotFound {
        User|sql:Error user = self.dbClient->queryRow(`SELECT * FROM users WHERE email = ?`, email);
        if user is sql:NoRowsError {
            return http:NotFound("User not found");
        }
        return user;
    }

    function 'shutdown'() {
        check self.dbClient->close();
    }
}