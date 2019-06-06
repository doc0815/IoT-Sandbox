# IoT-Sandbox

sandbox application for playing around with Electric Imp sensoric, the Mozilla Location Service (MLS), and MongoDB products

## Electric Imp sensoric

A communications protocol is established between a device (sensor) and an agent. The device samples sensor data (temperature, air pressure, humidity, etc.) with a regular frequency (controled by a parameter) and stores it internally together with the timestamp of recording. After a waiting time (also controlled by a parameter) it establishes a wifi connection and sends the recorded sensor data to the agent over the named channel *readings*. The device scans all available wifi networks in additions and sends these signal parameters also to the agent using the named channel *wifi*. Subsequently, the device disconnects and samples sensor data again until the next transmission cycle.

The agent adds the device's ID to the sensor data records and forwards them to the MongoDB Stitch application. A json format with these attributes is used: senorID, sensorTimestamp (millseconds elapsed since 01.01.1970 midnight), temperature (degree celsius), humidity, pressure, lightlevel, co2, voc.

Furthermore, the agent requests the current location of the device based on the scanned wifi data the device provides. Therefore, a POST request is created and sent to MLS. The service's reply is enriched with the device ID and the timestamp the location reply is received. The agent also forwards this data to the MongoDB Stitch application using these attributes (json format): senorID, sensorTimestamp (millseconds elapsed since 01.01.1970 midnight), location (longitude and latitude), accuracy (meter).

next step: implement 2nd sensor with cellular data transmission instead of wifi

## Mozilla Location Service (MLS)

Please refer to the documentation of the service's API:
https://mozilla.github.io/ichnaea/api/geolocate.html#api-geolocate-latest

## MongoDB Stitch

Two customized functions of the Stitch applications are used to insert sensor data into the MongoDB database. The function `logSensorReadings` receives an array of json documents and inserts them using the API call `insertMany()`. The collection in which the sensor readings are stored is `SensorData` in database `impExplorer`. `logSensorLocation` processes the sensor location data and writes it into the `testLocation` collection in database `impExplorer` using the API call `insertOne()`.

## MongoDB Atlas

The document oriented NoSQL database is run as a managed service on AWS.

## Data analysis

Within this sandbox the pipeline `last24hours` is implemented using a **Jupyter notebook** and the **MongoDB Compass** application. The pipeline has the these stages:
- keep (filter) all documents with a sensor timestamp within the last 24 hours
- date/time conversion of the sensor timestamp from 'millseconds elapsed since 01.01.1970' to time periods of 15 and/or 60 minutes duration
- aggregation (arithmetic mean, min/max, standard deviation) of the sensor measures (temperature, air pressure, humidity, etc.

todo: location data processing (after setting up 2nd sensor)

## Data visualisation

todo: choose Tableau, Qlik, etc. and create a display/dashboard
