- [elagto-key-light-linux](#elagto-key-light-linux)
  - [JSON filters in -t/--target](#json-filters-in--t--target)
    - [Filter basics](#filter-basics)
    - [Example target filters](#example-target-filters)

# elagto-key-light-linux

Small bash script to manage elgato key light and key light air.

The script will let you to manage one, many or all lights depending on what you set as target.

Allows discovery of devices, information collection directly from the lights, changing temperature, changing brightness and turning the lights on and off.

Intended for easy use via CLI, keyboard shortcuts and by StreamDeck, Cinnamon applets etc.

If you are using a StreamDeck you can target this script as a command for the button press.

## JSON filters in -t/--target

The target option is passing along filters to the json parser.
Specified filters will be inserted into the jq select and therefore allows you to utilize the full feature set and power of jq on the json result.

The script transforms the captured base data to JSON, to allow use of jq filtering independently of what output format you want.

jq allows you to pipe results to further transform, compare and parse in many ways. The threshold of starting to use JQ can feel a bit high for novice shell users and we therefore give you some [basic information on jq filters](#filter-basics) and [examples](#example-target-filters).

### Filter basics
The parameter data to pass in to the -t or --target option uses.(dot) notation of the JSON data.

**IMPORTANT! When specifying a filter you MUST do so within single quotes (') and use double quote (") around data values, as per jq standard. Not doing this will throw a jq parse error.**

The dot(.) notation to target a specific host based on its ipv4 address would be:

```bash
    '.ipv4 = "192.168.0.132"'
```

of for a nested JSON object like the serial number within the info object:
```bash
    '.info.serialNumber = "CW16K1A01748"'
```

Example of JSON result (see examples directory for more/full output examples):

```json
[
    {
        "device": "Elgato Key Light Air 0C2C",
        "manufacturer": "Elgato",
        "hostname": "elgato-key-light-air-0c2c.local",
        "url": "http://192.168.0.132:9123",
        "ipv4": "192.168.0.132",
        "ipv6": "N/A",
        "port": 9123,
        ...
        <omitted>
        ...        
        "light": {
            "numberOfLights": 1,
            "lights": [
                {
                    "on": 0,
                    "brightness": 31,
                    "temperature": 179
                }
            ]
        },
        ...
        <omitted>
        ... 
        "info": {
            "productName": "Elgato Key Light Air",
            "hardwareBoardType": 200,
            "firmwareBuildNumber": 199,
            "firmwareVersion": "1.0.3",
            "serialNumber": "CW16K1A01748",
            "displayName": "Front  Right",
            "features": [
                "lights"
            ]
        }
```

### Example target filters

Here you will find a list of examples for some common use cases that can be adapted to your liking.
[Filter basics](#filter-basics) provides you with the basic information about how filters are constructed.

Note! You can add the other formatting parameters as -p/--pretty -f/--format or specify any of the other action.

Perform action on all ligts that has "Left" (case sensitive) in their names:

```bash
./keylights.sh -t '.info.displayName | contains("Left")' <action>
```

Perform action on all ligts that has "front" in their names in a case insensitive manner:

```bash
./keylights.sh -t '.info.displayName | ascii_downcase | contains("front")' <action>
```
