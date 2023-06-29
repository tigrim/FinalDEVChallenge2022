**Final Task![](Aspose.Words.58540f0f-32a8-4ec3-9284-5e53c0941a36.001.jpeg)**

**iOS Developer | DEV Challenge XIX - Final**

**Content:**

1. [Task description](#_page0_x72.00_y370.88)
1. [Description of input data](#_page1_x72.00_y159.28)

You are developing an iPhone/iPad (Swift) application that is going to help determine the location of the lighting. There has been quite a lot of lightning in Ukraine lately and sometimes it is necessary to know where they are happening. This application should operate in two models:

**Sensor (Peer)**

A statically located device with a precise location. The purpose of the sensor is to detect and track loud events.

- the app should detect loud sounds.
- app should notify a user about recorded events.
- every event should be logged with a timestamp.
- events log should store between sessions.
- user can export loud events in JSON format.

**Analyzer (Host)**

The app receives logs and visualizes calculated boom points.

- there should be the ability to import information from **sensors.**
- user can look through received logs.
- calculates the location of the event and shows them on a map.
- user can export calculated points.
- calculated points are visible on the map with a possible calculation error.

The app should detect errors:

- duplicate eventId / sensorId.
- timestamps are too far away (the big difference will make it unreal to determine locations).
2. **Description<a name="_page1_x72.00_y159.28"></a> of input data**

For test purposes we will provide you with data to process in the analyzer application. See **[test_data.json](https://drive.google.com/file/d/1UhBf5TbAQqg0WNEL6kFbS4uTA90kzy2x/view?usp=sharing).**



|JSON sensor data format||
| - | :- |
|sensorId|UUID of the sensor, random per each installed app (optional)|
|eventId|UUID of particular loud event|
|timeStamp|UNIX time of event|
|lat|coordinate of event|
|lon|coordinate of event|

**Requirements:**

- The project should build on Xcode 14.0+.
- Language should be Swift.
- The target should support iPad
- Minimal iOS version is 15.0.
  
