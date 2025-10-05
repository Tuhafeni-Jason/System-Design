import ballerina/grpc;
import ballerina/protobuf;

public const string CAR_RENTAL_DESC = "0A1670726F746F2F6361725F72656E74616C2E70726F746F120A6361725F72656E74616C22F8010A03436172120E0A0269641801200128095202696412120A046D616B6518022001280952046D616B6512140A056D6F64656C18032001280952056D6F64656C12120A0479656172180420012805520479656172121F0A0B6461696C795F7072696365180520012801520A6461696C79507269636512180A076D696C6561676518062001280552076D696C65616765122D0A0673746174757318072001280E32152E6361725F72656E74616C2E4361725374617475735206737461747573121A0A086C6F636174696F6E18082001280952086C6F636174696F6E121D0A0A637265617465645F617418092001280952096372656174656441742292010A045573657212170A07757365725F6964180120012809520675736572496412120A046E616D6518022001280952046E616D6512140A05656D61696C1803200128095205656D61696C12280A04726F6C6518042001280E32142E6361725F72656E74616C2E55736572526F6C655204726F6C65121D0A0A637265617465645F6174180520012809520963726561746564417422450A094461746552616E6765121D0A0A73746172745F64617465180120012809520973746172744461746512190A08656E645F646174651802200128095207656E6444617465227C0A08436172744974656D12150A066361725F69641801200128095205636172496412380A0C72656E74616C5F646174657318022001280B32152E6361725F72656E74616C2E4461746552616E6765520B72656E74616C4461746573121F0A0B746F74616C5F7072696365180320012801520A746F74616C507269636522D3010A0B5265736572766174696F6E12250A0E7265736572766174696F6E5F6964180120012809520D7265736572766174696F6E496412170A07757365725F69641802200128095206757365724964122A0A056974656D7318032003280B32142E6361725F72656E74616C2E436172744974656D52056974656D7312210A0C746F74616C5F616D6F756E74180420012801520B746F74616C416D6F756E7412160A067374617475731805200128095206737461747573121D0A0A637265617465645F6174180620012809520963726561746564417422550A0F53756363657373526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D657373616765120E0A02696418032001280952026964226D0A0D4572726F72526573706F6E736512180A077375636365737318012001280852077375636365737312230A0D6572726F725F6D657373616765180220012809520C6572726F724D657373616765121D0A0A6572726F725F636F646518032001280552096572726F72436F6465224F0A074361724C69737412230A046361727318012003280B320F2E6361725F72656E74616C2E436172520463617273121F0A0B746F74616C5F636F756E74180220012805520A746F74616C436F756E74226F0A0F5265736572766174696F6E4C697374123B0A0C7265736572766174696F6E7318012003280B32172E6361725F72656E74616C2E5265736572766174696F6E520C7265736572766174696F6E73121F0A0B746F74616C5F636F756E74180220012805520A746F74616C436F756E74228F010A0C43617274526573706F6E736512180A077375636365737318012001280852077375636365737312180A076D65737361676518022001280952076D657373616765122A0A056974656D7318032003280B32142E6361725F72656E74616C2E436172744974656D52056974656D73121F0A0B746F74616C5F7072696365180420012801520A746F74616C5072696365224D0A0D4164644361725265717565737412210A0363617218012001280B320F2E6361725F72656E74616C2E436172520363617212190A0861646D696E5F6964180220012809520761646D696E49642288020A105570646174654361725265717565737412150A066361725F69641801200128095205636172496412190A0861646D696E5F6964180220012809520761646D696E496412120A046D616B6518032001280952046D616B6512140A056D6F64656C18042001280952056D6F64656C12120A0479656172180520012805520479656172121F0A0B6461696C795F7072696365180620012801520A6461696C79507269636512180A076D696C6561676518072001280552076D696C65616765122D0A0673746174757318082001280E32152E6361725F72656E74616C2E4361725374617475735206737461747573121A0A086C6F636174696F6E18092001280952086C6F636174696F6E22440A1052656D6F76654361725265717565737412150A066361725F69641801200128095205636172496412190A0861646D696E5F6964180220012809520761646D696E496422740A0F4C6973744361727352657175657374121F0A0B66696C7465725F6D616B65180120012809520A66696C7465724D616B65121F0A0B66696C7465725F79656172180220012805520A66696C74657259656172121F0A0B637573746F6D65725F6964180320012809520A637573746F6D65724964224A0A105365617263684361725265717565737412150A066361725F696418012001280952056361724964121F0A0B637573746F6D65725F6964180220012809520A637573746F6D657249642284010A10416464546F436172745265717565737412150A066361725F69641801200128095205636172496412380A0C72656E74616C5F646174657318022001280B32152E6361725F72656E74616C2E4461746552616E6765520B72656E74616C4461746573121F0A0B637573746F6D65725F6964180320012809520A637573746F6D65724964223A0A17506C6163655265736572766174696F6E52657175657374121F0A0B637573746F6D65725F6964180120012809520A637573746F6D6572496422320A174C6973745265736572766174696F6E735265717565737412170A07757365725F696418012001280952067573657249642A500A0943617253746174757312120A0E554E4B4E4F574E5F5354415455531000120D0A09415641494C41424C451001120F0A0B554E415641494C41424C451002120F0A0B4D41494E54454E414E434510032A350A0855736572526F6C6512100A0C554E4B4E4F574E5F524F4C451000120C0A08435553544F4D4552100112090A0541444D494E1002328A050A1043617252656E74616C5365727669636512400A0641646443617212192E6361725F72656E74616C2E416464436172526571756573741A1B2E6361725F72656E74616C2E53756363657373526573706F6E736512460A09557064617465436172121C2E6361725F72656E74616C2E557064617465436172526571756573741A1B2E6361725F72656E74616C2E53756363657373526573706F6E7365123E0A0952656D6F7665436172121C2E6361725F72656E74616C2E52656D6F7665436172526571756573741A132E6361725F72656E74616C2E4361724C697374123E0A0B437265617465557365727312102E6361725F72656E74616C2E557365721A1B2E6361725F72656E74616C2E53756363657373526573706F6E7365280112430A114C697374417661696C61626C6543617273121B2E6361725F72656E74616C2E4C69737443617273526571756573741A0F2E6361725F72656E74616C2E4361723001123A0A09536561726368436172121C2E6361725F72656E74616C2E536561726368436172526571756573741A0F2E6361725F72656E74616C2E43617212430A09416464546F43617274121C2E6361725F72656E74616C2E416464546F43617274526571756573741A182E6361725F72656E74616C2E43617274526573706F6E736512500A10506C6163655265736572766174696F6E12232E6361725F72656E74616C2E506C6163655265736572766174696F6E526571756573741A172E6361725F72656E74616C2E5265736572766174696F6E12540A104C6973745265736572766174696F6E7312232E6361725F72656E74616C2E4C6973745265736572766174696F6E73526571756573741A1B2E6361725F72656E74616C2E5265736572766174696F6E4C69737442280A166F72672E6578616D706C652E6361725F72656E74616C420E43617252656E74616C50726F746F620670726F746F33";

public isolated client class CarRentalServiceClient {
    *grpc:AbstractClientEndpoint;

    private final grpc:Client grpcClient;

    public isolated function init(string url, *grpc:ClientConfiguration config) returns grpc:Error? {
        self.grpcClient = check new (url, config);
        check self.grpcClient.initStub(self, CAR_RENTAL_DESC);
    }

    isolated remote function AddCar(AddCarRequest|ContextAddCarRequest req) returns SuccessResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddCarRequest message;
        if req is ContextAddCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/AddCar", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SuccessResponse>result;
    }

    isolated remote function AddCarContext(AddCarRequest|ContextAddCarRequest req) returns ContextSuccessResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddCarRequest message;
        if req is ContextAddCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/AddCar", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SuccessResponse>result, headers: respHeaders};
    }

    isolated remote function UpdateCar(UpdateCarRequest|ContextUpdateCarRequest req) returns SuccessResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdateCarRequest message;
        if req is ContextUpdateCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/UpdateCar", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <SuccessResponse>result;
    }

    isolated remote function UpdateCarContext(UpdateCarRequest|ContextUpdateCarRequest req) returns ContextSuccessResponse|grpc:Error {
        map<string|string[]> headers = {};
        UpdateCarRequest message;
        if req is ContextUpdateCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/UpdateCar", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <SuccessResponse>result, headers: respHeaders};
    }

    isolated remote function RemoveCar(RemoveCarRequest|ContextRemoveCarRequest req) returns CarList|grpc:Error {
        map<string|string[]> headers = {};
        RemoveCarRequest message;
        if req is ContextRemoveCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/RemoveCar", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <CarList>result;
    }

    isolated remote function RemoveCarContext(RemoveCarRequest|ContextRemoveCarRequest req) returns ContextCarList|grpc:Error {
        map<string|string[]> headers = {};
        RemoveCarRequest message;
        if req is ContextRemoveCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/RemoveCar", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <CarList>result, headers: respHeaders};
    }

    isolated remote function SearchCar(SearchCarRequest|ContextSearchCarRequest req) returns Car|grpc:Error {
        map<string|string[]> headers = {};
        SearchCarRequest message;
        if req is ContextSearchCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/SearchCar", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <Car>result;
    }

    isolated remote function SearchCarContext(SearchCarRequest|ContextSearchCarRequest req) returns ContextCar|grpc:Error {
        map<string|string[]> headers = {};
        SearchCarRequest message;
        if req is ContextSearchCarRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/SearchCar", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <Car>result, headers: respHeaders};
    }

    isolated remote function AddToCart(AddToCartRequest|ContextAddToCartRequest req) returns CartResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddToCartRequest message;
        if req is ContextAddToCartRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/AddToCart", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <CartResponse>result;
    }

    isolated remote function AddToCartContext(AddToCartRequest|ContextAddToCartRequest req) returns ContextCartResponse|grpc:Error {
        map<string|string[]> headers = {};
        AddToCartRequest message;
        if req is ContextAddToCartRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/AddToCart", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <CartResponse>result, headers: respHeaders};
    }

    isolated remote function PlaceReservation(PlaceReservationRequest|ContextPlaceReservationRequest req) returns Reservation|grpc:Error {
        map<string|string[]> headers = {};
        PlaceReservationRequest message;
        if req is ContextPlaceReservationRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/PlaceReservation", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <Reservation>result;
    }

    isolated remote function PlaceReservationContext(PlaceReservationRequest|ContextPlaceReservationRequest req) returns ContextReservation|grpc:Error {
        map<string|string[]> headers = {};
        PlaceReservationRequest message;
        if req is ContextPlaceReservationRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/PlaceReservation", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <Reservation>result, headers: respHeaders};
    }

    isolated remote function ListReservations(ListReservationsRequest|ContextListReservationsRequest req) returns ReservationList|grpc:Error {
        map<string|string[]> headers = {};
        ListReservationsRequest message;
        if req is ContextListReservationsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/ListReservations", message, headers);
        [anydata, map<string|string[]>] [result, _] = payload;
        return <ReservationList>result;
    }

    isolated remote function ListReservationsContext(ListReservationsRequest|ContextListReservationsRequest req) returns ContextReservationList|grpc:Error {
        map<string|string[]> headers = {};
        ListReservationsRequest message;
        if req is ContextListReservationsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeSimpleRPC("car_rental.CarRentalService/ListReservations", message, headers);
        [anydata, map<string|string[]>] [result, respHeaders] = payload;
        return {content: <ReservationList>result, headers: respHeaders};
    }

    isolated remote function CreateUsers() returns CreateUsersStreamingClient|grpc:Error {
        grpc:StreamingClient sClient = check self.grpcClient->executeClientStreaming("car_rental.CarRentalService/CreateUsers");
        return new CreateUsersStreamingClient(sClient);
    }

    isolated remote function ListAvailableCars(ListCarsRequest|ContextListCarsRequest req) returns stream<Car, grpc:Error?>|grpc:Error {
        map<string|string[]> headers = {};
        ListCarsRequest message;
        if req is ContextListCarsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("car_rental.CarRentalService/ListAvailableCars", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, _] = payload;
        CarStream outputStream = new CarStream(result);
        return new stream<Car, grpc:Error?>(outputStream);
    }

    isolated remote function ListAvailableCarsContext(ListCarsRequest|ContextListCarsRequest req) returns ContextCarStream|grpc:Error {
        map<string|string[]> headers = {};
        ListCarsRequest message;
        if req is ContextListCarsRequest {
            message = req.content;
            headers = req.headers;
        } else {
            message = req;
        }
        var payload = check self.grpcClient->executeServerStreaming("car_rental.CarRentalService/ListAvailableCars", message, headers);
        [stream<anydata, grpc:Error?>, map<string|string[]>] [result, respHeaders] = payload;
        CarStream outputStream = new CarStream(result);
        return {content: new stream<Car, grpc:Error?>(outputStream), headers: respHeaders};
    }
}

public isolated client class CreateUsersStreamingClient {
    private final grpc:StreamingClient sClient;

    isolated function init(grpc:StreamingClient sClient) {
        self.sClient = sClient;
    }

    isolated remote function sendUser(User message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function sendContextUser(ContextUser message) returns grpc:Error? {
        return self.sClient->send(message);
    }

    isolated remote function receiveSuccessResponse() returns SuccessResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, _] = response;
            return <SuccessResponse>payload;
        }
    }

    isolated remote function receiveContextSuccessResponse() returns ContextSuccessResponse|grpc:Error? {
        var response = check self.sClient->receive();
        if response is () {
            return response;
        } else {
            [anydata, map<string|string[]>] [payload, headers] = response;
            return {content: <SuccessResponse>payload, headers: headers};
        }
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.sClient->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.sClient->complete();
    }
}

public class CarStream {
    private stream<anydata, grpc:Error?> anydataStream;

    public isolated function init(stream<anydata, grpc:Error?> anydataStream) {
        self.anydataStream = anydataStream;
    }

    public isolated function next() returns record {|Car value;|}|grpc:Error? {
        var streamValue = self.anydataStream.next();
        if streamValue is () {
            return streamValue;
        } else if streamValue is grpc:Error {
            return streamValue;
        } else {
            record {|Car value;|} nextRecord = {value: <Car>streamValue.value};
            return nextRecord;
        }
    }

    public isolated function close() returns grpc:Error? {
        return self.anydataStream.close();
    }
}

public isolated client class CarRentalServiceSuccessResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendSuccessResponse(SuccessResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextSuccessResponse(ContextSuccessResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class CarRentalServiceReservationListCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendReservationList(ReservationList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextReservationList(ContextReservationList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class CarRentalServiceCarListCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendCarList(CarList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextCarList(ContextCarList response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class CarRentalServiceCarCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendCar(Car response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextCar(ContextCar response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class CarRentalServiceReservationCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendReservation(Reservation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextReservation(ContextReservation response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public isolated client class CarRentalServiceCartResponseCaller {
    private final grpc:Caller caller;

    public isolated function init(grpc:Caller caller) {
        self.caller = caller;
    }

    public isolated function getId() returns int {
        return self.caller.getId();
    }

    isolated remote function sendCartResponse(CartResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendContextCartResponse(ContextCartResponse response) returns grpc:Error? {
        return self.caller->send(response);
    }

    isolated remote function sendError(grpc:Error response) returns grpc:Error? {
        return self.caller->sendError(response);
    }

    isolated remote function complete() returns grpc:Error? {
        return self.caller->complete();
    }

    public isolated function isCancelled() returns boolean {
        return self.caller.isCancelled();
    }
}

public type ContextUserStream record {|
    stream<User, error?> content;
    map<string|string[]> headers;
|};

public type ContextCarStream record {|
    stream<Car, error?> content;
    map<string|string[]> headers;
|};

public type ContextCarList record {|
    CarList content;
    map<string|string[]> headers;
|};

public type ContextListReservationsRequest record {|
    ListReservationsRequest content;
    map<string|string[]> headers;
|};

public type ContextSuccessResponse record {|
    SuccessResponse content;
    map<string|string[]> headers;
|};

public type ContextUser record {|
    User content;
    map<string|string[]> headers;
|};

public type ContextRemoveCarRequest record {|
    RemoveCarRequest content;
    map<string|string[]> headers;
|};

public type ContextUpdateCarRequest record {|
    UpdateCarRequest content;
    map<string|string[]> headers;
|};

public type ContextReservationList record {|
    ReservationList content;
    map<string|string[]> headers;
|};

public type ContextAddToCartRequest record {|
    AddToCartRequest content;
    map<string|string[]> headers;
|};

public type ContextSearchCarRequest record {|
    SearchCarRequest content;
    map<string|string[]> headers;
|};

public type ContextAddCarRequest record {|
    AddCarRequest content;
    map<string|string[]> headers;
|};

public type ContextCartResponse record {|
    CartResponse content;
    map<string|string[]> headers;
|};

public type ContextReservation record {|
    Reservation content;
    map<string|string[]> headers;
|};

public type ContextCar record {|
    Car content;
    map<string|string[]> headers;
|};

public type ContextPlaceReservationRequest record {|
    PlaceReservationRequest content;
    map<string|string[]> headers;
|};

public type ContextListCarsRequest record {|
    ListCarsRequest content;
    map<string|string[]> headers;
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type CarList record {|
    Car[] cars = [];
    int total_count = 0;
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type ListReservationsRequest record {|
    string user_id = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type SuccessResponse record {|
    boolean success = false;
    string message = "";
    string id = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type User record {|
    string user_id = "";
    string name = "";
    string email = "";
    UserRole role = UNKNOWN_ROLE;
    string created_at = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type RemoveCarRequest record {|
    string car_id = "";
    string admin_id = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type ReservationList record {|
    Reservation[] reservations = [];
    int total_count = 0;
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type UpdateCarRequest record {|
    string car_id = "";
    string admin_id = "";
    string make = "";
    string model = "";
    int year = 0;
    float daily_price = 0.0;
    int mileage = 0;
    CarStatus status = UNKNOWN_STATUS;
    string location = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type CartItem record {|
    string car_id = "";
    DateRange rental_dates = {};
    float total_price = 0.0;
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type AddToCartRequest record {|
    string car_id = "";
    DateRange rental_dates = {};
    string customer_id = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type SearchCarRequest record {|
    string car_id = "";
    string customer_id = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type ErrorResponse record {|
    boolean success = false;
    string error_message = "";
    int error_code = 0;
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type CartResponse record {|
    boolean success = false;
    string message = "";
    CartItem[] items = [];
    float total_price = 0.0;
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type AddCarRequest record {|
    Car car = {};
    string admin_id = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type DateRange record {|
    string start_date = "";
    string end_date = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type Reservation record {|
    string reservation_id = "";
    string user_id = "";
    CartItem[] items = [];
    float total_amount = 0.0;
    string status = "";
    string created_at = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type Car record {|
    string id = "";
    string make = "";
    string model = "";
    int year = 0;
    float daily_price = 0.0;
    int mileage = 0;
    CarStatus status = UNKNOWN_STATUS;
    string location = "";
    string created_at = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type PlaceReservationRequest record {|
    string customer_id = "";
|};

@protobuf:Descriptor {value: CAR_RENTAL_DESC}
public type ListCarsRequest record {|
    string filter_make = "";
    int filter_year = 0;
    string customer_id = "";
|};

public enum CarStatus {
    UNKNOWN_STATUS, AVAILABLE, UNAVAILABLE, MAINTENANCE
}

public enum UserRole {
    UNKNOWN_ROLE, CUSTOMER, ADMIN
}
