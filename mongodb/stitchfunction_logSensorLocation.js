// function gets sensor data from the electric imp agent,
// does some simple conversions and inserts it into the MongoDB
exports = function (impData) {

  // transform the impData into an array of MongoDB documents
  sensorData = {
    sensorID:         impData.sensor,
    sensorTimestamp:  impData.timestamp * 1000, // conversion from s to ms
    accuracy:         impData.accuracy,
    location:         impData.location
  };

  // insert the location data into MongoDB
  const mongodb = context.services.get("mongodb-atlas");
  const sensorDataCollection = mongodb.db("impExplorer").collection("testLocation");

  return sensorDataCollection.insertOne(sensorData)
    //.then(result => console.log(`Successfully inserted item with _id: ${result.insertedId}`))
    .catch(err => console.error(`Failed to insert document: ${err}`));
};
