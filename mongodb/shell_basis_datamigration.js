// connect to the impExplorer collection
mongo "mongodb+srv://sandbox-qb8uy.mongodb.net/impExplorer" --username <paste username> --password <paste password>

// some basic analysis
db.SensorData.find({indoorTemp:{$exists:true}, indoorHumidity:{$exists:true}, timestamp:{$exists:true}}).count()
db.SensorData.find({indoorTemp:{$exists:true}, indoorHumidity:{$exists:true}, timestamp:{$exists:true}, date:{$exists:true}}).count()
db.SensorData.find({indoorTemp:{$exists:true}, indoorHumidity:{$exists:true}, timestamp:{$exists:true}, date:{$exists:false}}).count()
db.SensorData.find({sensorID:{$exists:false}}).count()
db.SensorData.find({test:"many"}).count()

// adding, renaming and deleting fields
db.SensorData.updateMany(
   {indoorTemp:{$exists:true}, indoorHumidity:{$exists:true}, timestamp:{$exists:true}, date:{$exists:true}},
   {$rename:{indoorTemp: "temperature", indoorHumidity: "humidity", timestamp: "sensorTimestamp"}, $unset:{date:""}}
)
db.SensorData.updateMany(
   {indoorTemp:{$exists:true}, indoorHumidity:{$exists:true}, timestamp:{$exists:true}, sensor:{$exists:true}},
   {$rename:{indoorTemp: "temperature", indoorHumidity: "humidity", timestamp: "sensorTimestamp", sensor: "sensorID"}}
)
db.SensorData.updateMany(
   {sensorID:{$exists:false}},
   {$set:{sensorID: "2391d553094457ee"}}
)
db.SensorData.updateMany(
   {sensor:{$exists:true}},
   {$rename:{sensor: "sensorID"}}
)
db.SensorData.deleteMany(
   {test:"many", temperature:{$exists:false}}
)
db.SensorData.updateMany(
   {test:"many"},
   {$rename:{indoorPressure: "pressure"}, $unset:{test:""}}
)
db.SensorData.updateMany(
   {},
   {$rename:{indoorPressure: "pressure"}}
)

// some timestamps have erroneously been added in seconds since 01.01.1970 (and not in ms)
// 1551906669975 is the timestamp when the first data had been created
db.SensorData.find({sensorTimestamp:{$lt:1551906669975}}).count()
db.SensorData.updateMany(
   {sensorTimestamp:{$lt:1551906669975}},
   {$mul:{sensorTimestamp: 1000}}
)
