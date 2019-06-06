// function gets sensor data from the electric imp agent,
// does some simple conversions and inserts it into the MongoDB
exports = function (impData) {
  
  // transform the impData into an array of MongoDB documents
  var tmpData = {};
  sensorData = [];
  for (let i = 0; i < impData.length; i++) {
    tmpData = {
      sensorID:         impData[i].sensor,
      sensorTimestamp:  impData[i].timestamp * 1000, // conversion from s to ms
      temperature:      impData[i].temperature,
      humidity:         impData[i].humidity,
      pressure:         impData[i].pressure,
      lightlevel:       impData[i].lightlevel,
      co2:              impData[i].co2,
      voc:              impData[i].voc
    };    
    sensorData.push(tmpData);
  }  
  
  // insert the sensor data into MongoDB collection SensorData
  const mongodb = context.services.get("mongodb-atlas");
  const sensorDataCollection = mongodb.db("impExplorer").collection("SensorData");
  
  return sensorDataCollection.insertMany(sensorData)
    .then(result => {
      console.log(`Successfully inserted ${result.insertedIds.length} items!`);
      return result;
    })
    .catch(err => console.error(`Failed to insert documents: ${err}`));
  
};
