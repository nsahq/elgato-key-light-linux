# elgato-key-light-linux

Small bash script to manage elgato key light and key light air.

The script will let you to manage one, many or all lights depending on what you set as target.

Allows discovery of devices, information collection directly from the lights, changing temperature, changing brightness and turning the lights on and off.

Intended for easy use via CLI, keyboard shortcuts and by StreamDeck, Cinnamon applets etc.

If you are using a StreamDeck you can target this script as a command for the button press.

## Installation

No installation or configuration required. Download, copy paste or git clone the repo to your local machine and run the script.

### Dependencies

The script requires avahi-browse, notify-send, jq and curl to be installed.

```bash
sudo apt-get install avahi-utils curl libnotify-bin jq
```

## Usage

Please see the docs sections to get examples and learn more about:

* [output formats - Have it your way](docs/output-formats.md)
* [-t/--target filters - The power of jq filtering](docs/target-filters.md)

```bash
Usage: keylights.sh [-h] [-f <value>] [-l <value>] [-p] [-s] [-t <value>][-v] [--<option>] [--<option> <value>] <action>

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

-h, --help               Print this help and exit
-f, --format             Set output format
-l, --limit <list>       Limit top level output fields to the specified comma separated list
-p, --pretty             Pretty print console output
-s, --silent             Supress notifications
-t, --target <filter>    Only perform action on devices where value matches filter
-v, --verbose            Print script debug info
```

## Example use cases

I have five lights in the room namned: Front Left, Front Right, front center, Rear Right, rear left.

I want to turn all lights on with my StreamDeck by setting a command to:

```bash
./keylights.sh on
```

I want to see the displayName, productName, serialNumber and firmwareVersion of all the lights on the right side of the room in a table:

```bash
./keylights.sh --target '.displayName | contains("Right")' --limit "displayName, productName, serialNumber, firmwareVersion"  --format table --pretty list
```

I want to let my StreamDeck button turn off all lights which contains the name "front" (not case sensitive due to ascii_downcase), i add the following to be a command on button press:

```bash
./keylights.sh --target '.displayName | ascii_downcase | contains("front")' off
```

I want to let my StreamDeck button turn off all lights which contains the name "Left" (case sensitive), I add the following to be a command on button press:

```bash
./keylights.sh --target '.displayName | contains("Left")' off
```
