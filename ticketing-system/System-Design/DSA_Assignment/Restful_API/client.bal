import ballerina/http;
import ballerina/io;

public enum AssetStatus { ACTIVE, UNDER_REPAIR, DISPOSED }

// Don't be scared by the amount of code here. It's mostly type definitions for requests and responses.
// Or in simple words it's stricks rules for how the data should be entered
// Prevents anyone from entering wrong data....almost.
type AssetRequest record {|
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
|};

type ScheduleRequest record {|
    string description;
    string frequency;
    string nextDueDate;
|};

// This code difines how the data will be sent back from the server
type ComponentResponse record {|
    string componentId;
    string name;
    string description;
|};

type ScheduleResponse record {|
    string scheduleId;
    string description;
    string frequency;
    string nextDueDate;
|};

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


http:Client clientEndpoint = check new (url="http://localhost:8080/api");


public function main() returns error? {
    //Befor anyone asks I have an emojy extension installed.
    //But if I'll be honest I used ai for most of the print statments since I had nothing creative to say.
    //And to rename varibles cuz I was getting too creative.
    io:println("▶️ Starting Comprehensive Asset Management Client...");

    //Add assets
    io:println("\n## 1. Adding initial assets..."); 
    
    AssetRequest engAssetReq = {assetTag: "ENG-001", name: "Laser Cutter", faculty: "Engineering", department: "Mechanical", status: ACTIVE, acquiredDate: "2025-01-10"};
    http:Response response1 = check clientEndpoint->post("/assets", engAssetReq);

    if (response1 is http:Response && response1.statusCode != 201) {
        io:println("❌ Failed to create asset: ${response1.message()}");
    }
    else{
        io:println("✅ Asset 'ENG-001' created.");
    }
    

    AssetRequest sciAssetReq = {assetTag: "SCI-001", name: "Spectrometer", faculty: "Science", department: "Chemistry", status: ACTIVE, acquiredDate: "2024-05-20"};
    http:Response response2 = check clientEndpoint->post("/assets", sciAssetReq);

    if (response2 is http:Response && response2.statusCode != 201) {
        io:println("❌ Failed to create asset: ${response1.message()}");
    }
    else{
        io:println("✅ Asset 'SCI-001' created.");
    }
    

    

    // Adds an overdue schedule to the Science asset 
    io:println("\n## 2. Adding an overdue schedule to 'SCI-001'...");
    
    // Date in the past to make it overdue.
    ScheduleRequest overdueSchedule = {description: "Annual Sensor Calibration", frequency: "YEARLY", nextDueDate: "2025-03-15"};
    http:Response response3 = check clientEndpoint->post(string `/assets/SCI-001/schedules`, overdueSchedule);
    
    if (response3 is http:Response && response3.statusCode != 201) {
        io:println("❌ Failed to add schedule: ${response3.message()}");
    }
    else{
    io:println("✅ Overdue schedule added to 'SCI-001'.");
    }
    

    // Viewing all assets
    io:println("\n## 3. Viewing all assets...");
    AssetResponse[] allAssets = check clientEndpoint->get("/assets");

    if (allAssets.length() == 0) {
        io:println("⚠️ No assets found in the system.");
    }
    else{
        foreach var asset in allAssets {
            io:println(`✅   -> ${asset.assetTag} | ${asset.name} | Status: ${asset.status}`);
        }
    }
  

    

    // Updating an asset
    io:println("\n## 4. Updating asset 'ENG-001'...");
    AssetRequest updateReq = {assetTag: "ENG-001", name: "Upgraded Laser Cutter", faculty: "Engineering", department: "Advanced Manufacturing", status: ACTIVE, acquiredDate: "2025-01-10"};
    
    AssetResponse updatedAsset = check clientEndpoint->put(string `/assets/ENG-001`, updateReq);

    if (updatedAsset.name != "Upgraded Laser Cutter") {
        io:println("❌ Asset update failed.");
    }
    else{
    io:println(`✅ Asset 'ENG-001' updated. New name: "${updatedAsset.name}"`);
    }
    

    // Viewing by faculty
    io:println("\n## 5. Viewing assets for faculty: Engineering...");
    AssetResponse[] engineeringAssets = check clientEndpoint->get("/assets/faculty/Engineering");
    io:println(`✅ Found ${engineeringAssets.length()} asset(s) in Engineering.`);
    foreach var asset in engineeringAssets {
        io:println(`   -> ${asset.assetTag} | ${asset.name}`);  //$ is dynamic string literal. Makes output cleaner.
    }

    

    //Overdue check 
    io:println("\n## 6. Performing overdue maintenance check...");
    AssetResponse[] overdueAssets = check clientEndpoint->get("/assets/overdue");
    io:println(`✅ Found ${overdueAssets.length()} asset(s) with overdue schedules.`);
    foreach var asset in overdueAssets {
        io:println(`   -> ⚠️ ${asset.assetTag} requires maintenance!`);
    }
    
    

    //Managing a component
    io:println("\n## 7. Adding a component to 'ENG-001'...");
    ComponentRequest componentReq = {name: "New Focusing Lens", description: "High-precision lens for fine cutting."};
    ComponentResponse newComponent = check clientEndpoint->post(string `/assets/ENG-001/components`, componentReq);
    io:println(`✅ Component '${newComponent.name}' added to 'ENG-001'.`);
    
    io:println("\n▶️ Client operations finished.");
}