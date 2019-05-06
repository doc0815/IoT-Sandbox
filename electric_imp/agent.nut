// CLOUD SERVICE LIBRARY

// MongoDB Stitch Library
#require "MongoDBStitch.agent.lib.nut:1.0.0"

// OTHER LIBRARIES & FUNCTIONS

// Library to manage agent/device communication
#require "MessageManager.lib.nut:2.2.0"

// constants required for MongoDB Stitch communications
const MONGO_DB_STITCH_API_KEY   = <todo>;
const MONGO_DB_STITCH_APP_ID    = "iot-tutorial-mdfmk";
const MONGO_DB_STITCH_FUN_WRITE = "logTemperatureReadings"

// APPLICATION
class IndoorSensor{
    
    // Class variables
    _stitch   = null;
    _mm       = null;
    _agentID  = null;
    _deviceID = null;

    constructor() {
        
        // initialize Stitch
        _stitch = MongoDBStitch(MONGO_DB_STITCH_APP_ID);

        // login to Stitch
        _stitch.loginWithApiKey(MONGO_DB_STITCH_API_KEY,
            function (error, response) {
                if (error) {
                    server.log("error during authenticating to MongoDB: " + error.details);
                }
            }
        );
        
        // configure message manager for device/agent communication
        _mm = MessageManager();
        _mm.on("readings", readingsHandler.bindenv(this));
        
        // Agent and Device IDs
        _agentID = split(http.agenturl(), "/").top();
        _deviceID = device.info().id;
        
    }
    
    function readingsHandler(msg, reply) {
        
        // add the device's ID to the data before sending it to Stitch
        foreach (reading in msg.data) {
            reading.sensor <- _deviceID;
            // log the data from the device. The data is a table, so use JSON encoding method convert to a string
            //server.log(http.jsonencode(reading));
        }
        
        // send data to Stitch
        _stitch.executeFunction(MONGO_DB_STITCH_FUN_WRITE, [msg.data],
            function (error, response) {
                if (error) {
                    server.log("error during sending to MongoDB: " + error.details);
                } else {
                    server.log("sensor data sent to MongoDB");
                }
            }
        );
    }

}

// RUNTIME
// ---------------------------------------------------
server.log("Agent running...");

// Run the Application
IndoorSensor();
