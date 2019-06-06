// CLOUD SERVICE LIBRARY

// MongoDB Stitch Library
#require "MongoDBStitch.agent.lib.nut:1.0.0"

// OTHER LIBRARIES & FUNCTIONS

// Library to manage agent/device communication
#require "MessageManager.lib.nut:2.2.0"

// Mozilla geolocation class
class MozillaGeolocate {
    
    static LOCATION_URL = "https://location.services.mozilla.com/v1/geolocate?key=";
    _apiKey = null;
    
    constructor(apiKey) {
        _apiKey = apiKey;
    }
    
    function getGeolocation(wifis, cb) {
        
        local url     = format("%s%s", LOCATION_URL, _apiKey);
        local headers = {"Content-Type": "application/json"};
        local body    = {"wifiAccessPoints": []};
        
        foreach (network in wifis) {
            body.wifiAccessPoints.append({
                "macAdress":      network.bssid,
                "signalStrength": network.rssi,
                "channel":        network.channel
            });
        }
        
        local request = http.post(url, headers, http.jsonencode(body));
        request.sendasync( function(res) {
            _locationRespHandler(wifis, res, cb);
        }.bindenv(this));
    }
    
    function _locationRespHandler(wifis, res, cb) {
        
        local body;
        local err = null;
        
        try {
            body = http.jsondecode(res.body);
        } catch(e) {
            imp.wakeup(0, function() { cb(e, res); }.bindenv(this) );
        }
        
        local statuscode = res.statuscode;
        switch(statuscode) {
            case 200:
                if ("location" in body) {
                    res = body;
                } else {
                    err = "The API request was valid, but no results were returned";
                }
                break;
            case 429:
                // too many requests try again in a second
                imp.wakeup(1, function() { getLocation(wifis, cb); }.bindenv(this));
                return;
            default:
                if ("message" in body) {
                    err = body.message;
                } else {
                    err = "Unexpected response from Mozilla";
                }
        }
        imp.wakeup(0, function() { cb(err, res); }.bindenv(this) );
    }
    
}


// constants required for MongoDB Stitch and Mozilla communications
const MONGO_DB_STITCH_API_KEY   = <todo>;
const MONGO_DB_STITCH_APP_ID    = "iot-tutorial-mdfmk";
const MOZILLA_GEOLOCATE_API_KEY = <todo>;

// APPLICATION
class IndoorSensor{
    
    // Class variables
    _stitch   = null;
    _geoloc   = null;
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
        
        // initialize Mozilla Geolocation
        _geoloc = MozillaGeolocate(MOZILLA_GEOLOCATE_API_KEY);
        
        // configure message manager for device/agent communication
        _mm = MessageManager();
        _mm.on("readings", readingsHandler.bindenv(this));
        _mm.on("wifi", wifiHandler.bindenv(this));
        
        // Agent and Device IDs
        _agentID = split(http.agenturl(), "/").top();
        _deviceID = device.info().id;
        
    }
    
    function readingsHandler(msg, reply) {
        
        // add the device's ID to the data before sending it to Stitch
        foreach (reading in msg.data) {
            reading.sensor <- _deviceID;
            // log the sensor data from the device
            //server.log(http.jsonencode(reading));
        }
        
        // send data to Stitch
        _stitch.executeFunction("logSensorReadings", [msg.data],
            stitchResponseHandler.bindenv(this));
    }
    
    function wifiHandler(msg, reply) {
        // call the Mozilla geolocate service asynchronously
        _geoloc.getGeolocation(msg.data, geoResponseHandler.bindenv(this));
    }
    
    function geoResponseHandler(error, response) {
        if (error) {
            server.log("error during getting location: " + error);
        } else {
            // add the device's ID and the response timestamp to the response
            // before sending it to Stitch
            response.timestamp <- time();
            response.sensor <- _deviceID;
            // log the wifi data
            //server.log(http.jsonencode(response));
            
            // send data to Stitch
            _stitch.executeFunction("logSensorLocation", [response],
                stitchResponseHandler.bindenv(this));
        }
    }
    
    function stitchResponseHandler(error, response) {
        if (error) {
            server.log("error during sending to MongoDB: " + error.details);
        } else {
            server.log("data sent successfully to MongoDB");
        }
    }
}

// RUNTIME
// ---------------------------------------------------
server.log("Agent running...");

// Run the Application
IndoorSensor();
