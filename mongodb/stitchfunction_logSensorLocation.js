// function gets sensor data from the electric imp agent,
// does some simple conversions and inserts it into the MongoDB
exports = function (impData) {

  // transform the impData into an array of MongoDB documents
  sensorData = {
    sensorID:         impData.sensor,
    // convert timestamp measured in seconds since 01/01/1970 into a date data type (timezone UTC)
    sensorTimestamp:  new Date (impData.timestamp * 1000),
    accuracy:         impData.accuracy,
    // convert to GeoJSON object
    location:         {type: "Point", coordinates: [impData.location.lng, impData.location.lat]}
  };

  // insert the location data into MongoDB
  const mongodb = context.services.get("mongodb-atlas");
  const sensorDataCollection = mongodb.db("impExplorer").collection("testLocation");

  return sensorDataCollection.insertOne(sensorData)
    //.then(result => console.log(`Successfully inserted item with _id: ${result.insertedId}`))
    .catch(err => console.error(`Failed to insert document: ${err}`));
};
