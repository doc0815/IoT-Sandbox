// SENSOR LIBRARIES

// Temperature Humidity sensor Library
#require "HTS221.device.lib.nut:2.0.1"
// Air Pressure sensor Library
#require "LPS22HB.device.lib.nut:2.0.0"

// OTHER LIBRARIES & FUNCTIONS

// Library to manage agent/device communication
#require "MessageManager.lib.nut:2.2.0"

// HARDWARE ABSTRACTION LAYER
ExplorerKit_001 <- {
    "LED_SPI"                   : hardware.spi257,
    "SENSOR_AND_GROVE_I2C"      : hardware.i2c89,
    "TEMP_HUMID_I2C_ADDR"       : 0xBE,
    "ACCEL_I2C_ADDR"            : 0x32,
    "PRESSURE_I2C_ADDR"         : 0xB8,
    "CO2_I2C_ADDR"              : 0xB0,
    "POWER_GATE_AND_WAKE_PIN"   : hardware.pin1,
    "AD_GROVE1_DATA1"           : hardware.pin2,
    "AD_GROVE2_DATA1"           : hardware.pin5
}

// Sensirion Gas Sensor SGP30
// there is no official library for this sensor available on electric imp
class SGP30{
    
    static VERSION = "1.0.0";

    // 8-bit Register addresses
    static REG_SERIAL_0       = 0x36;
    static REG_SERIAL_1       = 0x82;
    static REG_MEASURE_TEST_0 = 0x20;
    static REG_MEASURE_TEST_1 = 0x32;
    static REG_INIT_AIRQ_0    = 0x20;
    static REG_INIT_AIRQ_1    = 0x03;
    static REG_MEASURE_AIRQ_0 = 0x20;
    static REG_MEASURE_AIRQ_1 = 0x08;
    static REG_BASELINE_0     = 0x20;
    static REG_BASELINE_1     = 0x15;
    static REG_MEASURE_RAW_0  = 0x20;
    static REG_MEASURE_RAW_1  = 0x50;

    // Class variables
    _i2c  = null;
    _addr = null;

    constructor(i2c = null, addr = 0xB0){
        if (i2c == null) {
            server.error("SGP30 requires a valid imp I2C object");
            return null;
        }
        _i2c  = i2c;
        _addr = addr;    
    }
    
    function getSerial(){
        _i2c.write(_addr, REG_SERIAL_0.tochar()+REG_SERIAL_1.tochar());
        imp.sleep(0.0005);
        local val = _i2c.read(_addr, "", 9);
        if (val == null) throw "I2C read error: " + _i2c.readerror();
        return val;
        
    }
    
    function measureTest(){
        _i2c.write(_addr, REG_MEASURE_TEST_0.tochar()+REG_MEASURE_TEST_1.tochar());
        imp.sleep(0.220);
        local val = _i2c.read(_addr, "", 3);
        if (val == null) throw "I2C read error: " + _i2c.readerror();
        return val;
    }
    
    function initAirQuality() {
        _i2c.write(_addr, REG_INIT_AIRQ_0.tochar()+REG_INIT_AIRQ_1.tochar());
        imp.sleep(0.01);
        return 0;
    }
    
    function measureAirQuality(){
        _i2c.write(_addr, REG_MEASURE_AIRQ_0.tochar()+REG_MEASURE_AIRQ_1.tochar());
        imp.sleep(0.012);
        local val = _i2c.read(_addr, "", 6);
        if (val == null) throw "I2C read error: " + _i2c.readerror();
        local co2eq = ((val[0] << 8) | val[1]);
        local tvoc = ((val[3] << 8) | val[4]);
        return {"CO2eq" : co2eq, "TVOC" : tvoc};
    }

    function getBaseline() {
        _i2c.write(_addr, REG_BASELINE_0.tochar()+REG_BASELINE_1.tochar());
        imp.sleep(0.01);
        local val = _i2c.read(_addr, "", 6);
        if (val == null) throw "I2C read error: " + _i2c.readerror();
        local co2eq_base = ((val[0] << 8) | val[1]);
        local tvoc_base = ((val[3] << 8) | val[4]);
        return {"CO2eq_base" : co2eq_base, "TVOC_base" : tvoc_base};
    } 

    function measureRawSignals() {
        _i2c.write(_addr, REG_MEASURE_RAW_0.tochar()+REG_MEASURE_RAW_1.tochar());
        imp.sleep(0.025);
        local val = _i2c.read(_addr, "", 6);
        if (val == null) throw "I2C read error: " + _i2c.readerror();
        local h2 = ((val[0] << 8) | val[1]);
        local ethanol = ((val[3] << 8) | val[4]);
        return {"h2" : h2, "ethanol" : ethanol};
    }
    
}

// APPLICATION
class IndoorSensor{

    // Time in seconds to wait between readings
    static READING_INTERVAL_SEC = 60;
    // Time in seconds to wait between connections
    static REPORTING_INTERVAL_SEC = 1800;
    // Time to wait after boot before turning off WiFi
    static BOOT_TIMER_SEC = 120;
    
    // Hardware variables
    i2c             = ExplorerKit_001.SENSOR_AND_GROVE_I2C;
    tempHumidAddr   = ExplorerKit_001.TEMP_HUMID_I2C_ADDR;
    pressureAddr    = ExplorerKit_001.PRESSURE_I2C_ADDR;
    co2Addr         = ExplorerKit_001.CO2_I2C_ADDR;

    // Sensor variables
    tempSensor      = null;
    pressureSensor  = null;
    co2Sensor       = null;

    // Message Manager variable
    mm = null;

    // An array to store readings between connections
    readings = [];

    // Variable to track when to connect
    nextConnectTime = null;

    // Flag to track first disconnection
    _boot = true;

    constructor() {
        // Power save mode will reduce power consumption when the radio is idle,
        // a good first step for saving power for battery powered devices.
        // Power save mode will add latency when sending data.
        // Power save mode is not supported on impC001 and is recommended for
        // imp004m, so don't set for those types of imps.
        local type = imp.info().type;
        if (type != "imp004m" && type != "impC001") {
            imp.setpowersave(true);
        }
        
        // Configure message manager for device/agent communication
        mm = MessageManager();
        
        //
        // The acknowledge callback function is now message name specific.
        //
        // Message Manager allows us to call a function when a message
        // has been delivered. We will use this to know when it is ok
        // to delete locally stored readings and disconnect
        //mm.onAck(readingsAckHandler.bindenv(this));
        
        initializeSensors();
        
        // We want to make sure we can always blinkUp a device when it is first
        // powered on, so we do not want to immediately disconnect after boot
        // Set up first disconnect
        imp.wakeup(BOOT_TIMER_SEC, function() {
            _boot = false;
            server.disconnect();
        }.bindenv(this));
    }
    
    function run() {
        
        // Take an async temp/humid reading
        tempSensor.read(function(result) {
            
            // Set up the reading table with a timestamp
            local reading = { };
            reading.timestamp <- time();
            
            // Add temperature and humidity readings
            if ("temperature" in result) reading.temperature <- result.temperature;
            if ("humidity" in result) reading.humidity <- result.humidity;
            
            // Add air pressure conditions
            result = pressureSensor.read();
            if ("pressure" in result) reading.pressure <- result.pressure;
            
            // Add light level
            reading.lightlevel <- hardware.lightlevel();
            
            // Add air quality
            result = co2Sensor.measureAirQuality();
            if ("CO2eq" in result) reading.co2 <- result.CO2eq;
            if ("TVOC" in result) reading.voc <- result.TVOC;
            //co2Sensor.measureRawSignals();
            //co2Sensor.getBaseline();
            
            // Add table to the readings array for storage til next connection
            readings.push(reading);
            
            // Only send readings if we have some and are either already
            // connected or if it is time to connect
            if (readings.len() > 0 && (server.isconnected() || timeToConnect())) {
                sendReadings();
            }
            
            // Schedule the next reading
            imp.wakeup(READING_INTERVAL_SEC, run.bindenv(this));
        }.bindenv(this));
        
    }
    
    function sendReadings() {
        // Connect device
        server.connect();
        
        // Send sensor readings and wifi information to the agent
        mm.send("readings", readings, {"onAck": readingsAckHandler.bindenv(this)});
        //mm.send("wifi", imp.scanwifinetworks()); // disabled
        // Note: when the readings message is acknowledged by the agent and
        // the readingsAckHandler will be triggered
        
        // Update the next connection time varaible
        setNextConnectTime();
    }
    
    function readingsAckHandler(msg) {
        // Clear readings we just sent
        readings = [];
        // Disconnect from server if we have not just booted up
        if (!_boot) server.disconnect();
    }
    
    function timeToConnect() {
        // Return a boolean - if it is time to connect based on the current time
        return (time() >= nextConnectTime);
    }
    
    function setNextConnectTime() {
        // Update the local nextConnectTime variable
        nextConnectTime = time() + REPORTING_INTERVAL_SEC;
    }
    
    function initializeSensors() {
        // Configure i2c
        i2c.configure(CLOCK_SPEED_400_KHZ);
        
        // Initialize sensor
        tempSensor = HTS221(i2c, tempHumidAddr);
        pressureSensor = LPS22HB(i2c, pressureAddr);
        co2Sensor = SGP30(i2c, co2Addr);
        
        // Configure sensor to take readings
        tempSensor.setMode(HTS221_MODE.ONE_SHOT);
        pressureSensor.setMode(LPS22HB_MODE.ONE_SHOT);
        pressureSensor.softReset();
        
        // Calibrate co2 sensor
        //server.log("serial number CO2 sensor:");
        //server.log(co2Sensor.getSerial());
        // measureTest() will reset the baseline and requires a subsequent 
        // call of initAirQuality() !!!
        //server.log("CO2 sensor test measure:");
        //server.log(co2Sensor.measureTest());
        co2Sensor.initAirQuality();
        local maxCalibrationTime = time() + 60; // wait max 60 sec for calibration
        local res = co2Sensor.getBaseline();
        do {
            if ( (time()-maxCalibrationTime) > 0 )
                throw "CO2 sensor calibration: maximum wait time exceeded";
            co2Sensor.measureAirQuality();
            imp.sleep(1); // wait 1 sec
            res = co2Sensor.getBaseline();
        } while ( (res.CO2eq_base == 0) && (res.TVOC_base == 0) )
        
    }    
}

// RUNTIME
// ---------------------------------------------------
server.log("Device running...");

// Initialize application
sensor <- IndoorSensor();

// Start reading loop
sensor.run();
