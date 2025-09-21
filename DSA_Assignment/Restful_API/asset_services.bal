import ballerina/http;
import ballerina/log;
import ballerina/time;



public enum AssetStatus { ACTIVE, UNDER_REPAIR, DISPOSED }
public enum WorkOrderStatus { OPEN, IN_PROGRESS, COMPLETED, CANCELLED }
public enum TaskStatus { PENDING, IN_PROGRESS, COMPLETED }


// Don't be scared by the amount of code here. It's mostly type definitions for requests and responses.
// Or in simple words it's strict rules for how the data should be entered
// Since http resource function must return 'anydata' or specific http response types



type AssetCreateRequest record {|
    string assetTag;
    string name;
    string faculty;
    string department;
    AssetStatus status;
    string acquiredDate;
|};

type ComponentRequest record {|
    string name;
    string description;
    string? serialNumber;
|};

type ComponentResponse record {|
    string componentId;
    string name;
    string description;
|};

type ScheduleRequest record {|
    string scheduleId;
    string description;
    string frequency;
    string nextDueDate;
|};

type ScheduleResponse record {|
    string scheduleId;
    string description;
    string frequency;
    string nextDuedate;
|};

type Component record {|
    readonly string componentId;
    string name;
    string description;
    string? serialNumber;
    readonly string dateAdded;
|};

// Add other record types like MaintenanceSchedule, WorkOrder, Task here...

type AssetResponse record {|
    string assetTag;
    string name;
    string faculty;
    string department;
    AssetStatus status;
    string acquiredDate;
    map<ComponentResponse> components;
    map<ScheduleResponse> schedules;
|};


class Asset {
    
    public final string assetTag;
    public string name;
    public string faculty;
    public string department;
    public AssetStatus status;
    public final string acquiredDate;
    public map<Component> components = {};
       function init(AssetCreateRequest req) {
        self.assetTag = req.assetTag; //self is the same as this in java
        self.name = req.name;           //Both are used to refare to the attributes within the class. Something to do with in inheritance 
        self.faculty = req.faculty;
        self.department = req.department;
        self.status = req.status;
        self.acquiredDate = req.acquiredDate;
    }

    // This method contains the logic for adding a component.
    // It modifies the object's internal state directly.

    public function addComponent(ComponentRequest req) returns Component {
        string componentId = generateId("COMP");
        Component newComponent = {
            componentId: componentId,
            name: req.name,
            description: req.description,
            serialNumber: req.serialNumber,
            dateAdded: getCurrentDate()
        };
        self.components[componentId] = newComponent;
        return newComponent;
    } //Ngl gang this is all ai cuz I could not figure it out




    // Was having trouble with serialization so I for sure made this with ai help
// Converts internal Asset to AssetResponse for safe serialization. Whatever that
    public function toResponse() returns AssetResponse {
    map<ComponentResponse> compResponses = {};
    foreach string compId in self.components.keys() {
        Component? compOpt = self.components[compId];
        if compOpt is Component {
            Component comp = compOpt;
            compResponses[compId] = {
                componentId: comp.componentId,
                name: comp.name,
                description: comp.description
            };
        }
    }
    map<ScheduleResponse> scheduleResponses = {};

    return {
        assetTag: self.assetTag,
        name: self.name,
        faculty: self.faculty,
        department: self.department,
        status: self.status,
        acquiredDate: self.acquiredDate,
        components: compResponses,
        schedules: scheduleResponses
    };
  }

}






 
// The map holds references to the Asset objects.
map<Asset> assetDatabase = {};

// Note $ is a dynamic string literal. Makes output cleaner.
function generateId(string prefix) returns string {
    return string `${prefix}-${time:utcNow()[0]}`;
}

function getCurrentDate() returns string {
    time:Civil civilTime = time:utcToCivil(time:utcNow());
    string month = civilTime.month < 10 ? "0" + civilTime.month.toString() : civilTime.month.toString();
    string day = civilTime.day < 10 ? "0" + civilTime.day.toString() : civilTime.day.toString();
    return civilTime.year.toString() + "-" + month + "-" + day;
}

 //CORS stands for Cross-Origin Reasource Sharing
 //Allow Servers from different domains to communicate 
@http:ServiceConfig {
    cors: { allowOrigins: ["*"], allowHeaders: ["*"], allowMethods: ["*"] }
}
service /api on new http:Listener(8080) {

    //http:NotFound is a helper function which returns the status code '404 Not Found'
    private function findAsset(string assetTag) returns Asset|http:NotFound {
        if assetDatabase.hasKey(assetTag) {
            return assetDatabase.get(assetTag);
        }
        return <http:NotFound>{body: re `Asset not found: ${assetTag}`};
    }


    // Creates a new asset
    resource function post assets(@http:Payload AssetCreateRequest req) returns AssetResponse|http:Conflict {
        if assetDatabase.hasKey(req.assetTag) {
            return <http:Conflict>{body: re `Asset with tag ${req.assetTag} already exists`};
        }
        
        Asset newAsset = new (req);
        assetDatabase[req.assetTag] = newAsset;
        log:printInfo("Created new asset: " + req.assetTag);
        return newAsset.toResponse();
    }
    
    // Viewing all assets
    resource function get assets() returns AssetResponse[] {
        AssetResponse[] assetArray = [];
        foreach Asset asset in assetDatabase {
            assetArray.push(asset.toResponse());
        }
        return assetArray;
    }
    
    // Returns a single Asset asset or an error.
    resource function get assets/[string assetTag]() returns AssetResponse|http:NotFound {
        var assetResult = self.findAsset(assetTag);
        if assetResult is Asset {
            return assetResult.toResponse();
        }
        return assetResult;
    }

    resource function get assets/faculty/[string faculty]() returns AssetResponse[] {
        AssetResponse[] results = [];
        foreach Asset asset in assetDatabase {
            if asset.faculty == faculty {
                results.push(asset.toResponse());
            }
        }
        return results;
    }
    
    
    

    resource function post assets/[string assetTag]/components(@http:Payload ComponentRequest req) returns ComponentResponse|http:NotFound {
        var assetResult = self.findAsset(assetTag);
        
         if assetResult is Asset {
            Component newComp = assetResult.addComponent(req);
            return {
                componentId: newComp.componentId,
                name: newComp.name,
                description: newComp.description
            };
        }

        return assetResult; 
    }

   resource function get assets/[string assetTag]/components() returns ComponentResponse[]|http:NotFound {
    var assetResult = self.findAsset(assetTag);

    if assetResult is Asset {
        ComponentResponse[] componentArray = [];
        foreach string compId in assetResult.components.keys() {
            Component? compOpt = assetResult.components[compId];
            if compOpt is Component {
                Component comp = compOpt;
                componentArray.push({
                    componentId: comp.componentId,
                    name: comp.name,
                    description: comp.description
                });
            }
        }
        return componentArray;
    }
    return assetResult;
 }
}