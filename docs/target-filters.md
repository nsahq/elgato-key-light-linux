# -t/--target filters - The power of jq
This document is a cheat sheet/quick guide of getting you started with filtering out the light targets you want.

- [-t/--target filters - The power of jq](#-t--target-filters---the-power-of-jq)
  - [JSON filters used in -t/--target](#json-filters-used-in--t--target)
    - [Filter basics](#filter-basics)
    - [Example target filters](#example-target-filters)

## JSON filters used in -t/--target

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

or for a nested JSON object like the power on behaviour within the settings object:

```bash
    '.settings.powerOnBehavior" == 1'
```

while .(dot) notation is used to target underlying objects, you can also search in nested arrays by piping them '|' and catching/expanding them with '[]' like this:

```bash
'.lights | .[].on == 0'
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

Perform action on all lights that are currently switched on (notice the array expansion with | .[])):

```bash
./keylights.sh -t '.lights | .[].on == 1' <action>
```
