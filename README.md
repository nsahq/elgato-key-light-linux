- [elagto-key-light-linux](#elagto-key-light-linux)
  - [USAGE](#usage)
  - [Installation](#installation)
    - [Dependencies](#dependencies)
  - [JSON filters in -t/--target](#json-filters-in--t--target)
    - [Filter basics](#filter-basics)
    - [Example target filters](#example-target-filters)

# elagto-key-light-linux

Small bash script to manage elgato key light and key light air.

The script will let you to manage one, many or all lights depending on what you set as target.

Allows discovery of devices, information collection directly from the lights, changing temperature, changing brightness and turning the lights on and off.

Intended for easy use via CLI, keyboard shortcuts and by StreamDeck, Cinnamon applets etc.

If you are using a StreamDeck you can target this script as a command for the button press.

## USAGE

```bash
Usage: keylights.sh [-h] [-f <value>] [-l] [-p] [-s] [-t <value>][-v] [--<option>] [--<option> <value>] <action>

Elgato Lights controller. Works for Key Light and Key Light Air.

Available actions:
    list        List available lights
    status      Get state of lights
    on          Turn all lights on
    off         Turn all lights off
    temperature Set temperature level (260-470)
    brightness  Set brightness level (0-100)
    increase    Increases brightness by 10
    decrease    Decreases brightness by 10

Available formats:
    json        Renders output as JSON (default)
    simple      Renders output as JSON array of single level objects with subarrays as .(dot) notation JSON
    flat        Renders output as fully flattened single level JSON with .(dot) notation JSON
    html        Renders output as basic html table
    csv         Renders output as csv
    table       Renders output as a printed table
    pair        Renders output as flattened key=value pairs


Available options:

-h, --help      Print this help and exit
-f  --format    Set output format
-p, --pretty    Pretty print console output
-s, --silent    Supress notifications
-t, --target    Only perform action on devices where value matches filter
-v, --verbose   Print script debug info
```

## Installation

No installation or configuration required. Download, copy paste or git clone the repo to your local machine and run the script.

### Dependencies

The script requires avahi-browse, notify-send, jq and curl to be installed.

```bash
sudo apt-get install avahi-utils curl notify-send jq
```

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
    '.ipv4 == "192.168.0.132"'
```

of for a nested JSON object like the serial number within the info object:

```bash
    '.serialNumber == "CW16K1A01748"'
```

Example of JSON result (see examples directory for more/full output examples):

```json
[
    {
        "productName": "Elgato Key Light Air",
        "firmwareVersion": "1.0.3",
        "displayName": "Front  Right",
        "device": "Elgato Key Light Air 0C2C",
        "url": "http://192.168.0.132:9123",
        "ipv4": "192.168.0.132",
        ...
        <omitted>
        ...        
        "numberOfLights": 1,
        "lights": [
            {
                "on": 0,
                "brightness": 31,
                "temperature": 179
            }
        ]
        "settings": {
            "powerOnBehavior": 1,
            "powerOnBrightness": 20,
            "powerOnTemperature": 213,
            "switchOnDurationMs": 100,
            "switchOffDurationMs": 300,
            "colorChangeDurationMs": 100
        }
```

### Example target filters

Here you will find a list of examples for some common use cases that can be adapted to your liking.
[Filter basics](#filter-basics) provides you with the basic information about how filters are constructed.

Note! You can add the other formatting parameters as -p/--pretty -f/--format or specify any of the other action.

Perform action on all lights that exactly matches "Front Right" (case sensitive) in their names:

```bash
./keylights.sh -t '.displayName == "Front Right")' <action>
```

Perform action on all lights that has "Left" (case sensitive) in their names:

```bash
./keylights.sh -t '.displayName | contains("Left")' <action>
```

Perform action on all lights that has "front" in their names in a case insensitive manner:

```bash
./keylights.sh -t '.displayName | ascii_downcase | contains("front")' <action>
```

Perform action on all lights that have a duration of 100 ms when switched on (notice the object expansion with .(dot)):

```bash
./keylights.sh -t '.settings.switchOnDurationMs == 100)' <action>
```
