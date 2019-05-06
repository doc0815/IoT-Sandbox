# IoT-Sandbox

sandbox application for playing around with Electric Imp sensoric and MongoDB

## Electric Imp sensoric

A communications protocol is established between a device (sensor) and an agent. The device samples sensor data (temperature, air pressure, humidity, etc.) with a regular frequency (controled by a parameter) and stores it internally together with the timestamp of recording. After a waiting time (also controlled by a parameter) it establishes a wifi connection and sends the recorded sensor data to the agent. Subsequently, the device disconnects and samples sensor data again.
The agent adds the device's ID to the data record and forwards it to the MongoDB stitch application. A json format with these attributes is used: senorID, sensorTimestamp (ms elapsed since 01.01.1970 midnight), temperature (degree celsius), humidity, pressure, lightlevel, co2, voc.

## MongoDB
