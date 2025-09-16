import ballerina/http;
import ballerina/io;
import ballerina/file;
//import ballerina/uuid;


map<json> assetMap = {};
const string ASSET_DIR = "./assets"; //Where JSON files are stored



//load assets when program starts
function init() returns error? {
    check loadAssets();
}

//Load all JSON files from assets folder into memory
function loadAssets() returns error? {
    //Test if assets folder exits, if not create it
    var dirTest = file:test(ASSET_DIR, file:IS_DIR);
    if (dirTest is boolean) {
        if (!dirTest) {
            check file:createDir(ASSET_DIR);
            io:println("📂 Created assets directory: ", ASSET_DIR);
            return;
        }
    } else {
        return dirTest; 
    }
    //Read all files in assets folder
    
    file:MetaData[] entries = check file:readDir(ASSET_DIR);

    foreach file:MetaData meta in entries {
        if meta.dir {
            continue; 
        }
        string fname = check file:basename(meta.absPath);
        if !fname.endsWith(".json") {
            continue;
        }

        string content = check io:fileReadString(meta.absPath);
        json asset = check content.fromJsonString();
        assetMap[fname] = asset;
    }

    io:println("✅ Loaded assets from disk: ", assetMap.keys());
    return;
}

//Http Service
service / on new http:Listener(8080) {

 
}