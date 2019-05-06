# IoT-Sandbox

sandbox application for playing around with Electric Imp sensoric and MongoDB

## Electric Imp sensoric

A communications protocol is established between a device (sensor) and an agent. The device samples sensor data (temperature, air pressure, humidity, etc.) with a regular frequency (controled by a parameter) and stores it internally together with the timestamp of recording. After a waiting time (also controlled by a parameter) it establishes a wifi connection and sends the recorded sensor data to the agent. Subsequently, the device disconnects and samples sensor data again.
The agent adds the device's ID to the data record and forwards it to the MongoDB Stitch application. A json format with these attributes is used: senorID, sensorTimestamp (millseconds elapsed since 01.01.1970 midnight), temperature (degree celsius), humidity, pressure, lightlevel, co2, voc.

## MongoDB

The customized function 'logTemperatureReadings' of the MongoDB Stitch application receives an array of json documents and inserts them into MongoDB using the API call insertMany(). The collection in which the sensor data is stored is 'SensorData' in database 'impExplorer'.

Within this sandbox the pipeline 'last24hours' is implemented using a Jupyter notebook and the MongoDB Compass application. The pipeline has the these stages:
- keep (filter) all documents with a sensor timestamp within the last 24 hours
- date/time conversion of the sensor timestamp from 'millseconds elapsed since 01.01.1970' to time periods of 15 and/or 60 minutes duration
- aggregation (arithmetic mean, min/max, standard deviation) of the sensor measures (temperature, air pressure, humidity, etc.
