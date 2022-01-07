# Output formats - Have it your way

- [Output formats - Have it your way](#output-formats---have-it-your-way)
  - [JSON - Examples of JSON output](#json---examples-of-json-output)
    - [json](#json)
    - [simple](#simple)
    - [flat](#flat)
  - [csv - Examples of csv output](#csv---examples-of-csv-output)
  - [table - Examples of table output](#table---examples-of-table-output)
  - [pair - Examples of key/value output](#pair---examples-of-keyvalue-output)
  - [html - Examples of html table output](#html---examples-of-html-table-output)


The scripts allows you to extract the information about the lights in multiple ways. Per default you will get JSON formated printouts.

The -p/--pretty option is available and stacks with all formats to make the output easier to read for humans.

To select and output only the data you want, you can specifiy a comma separated list with the -l/--limit option. The values to choose from can be seen in the example files for full json, and the values will be the same regardless of the chosen output format. Do note that you can only specify the first level objects and the order you place the objects in will be the order in the resulting output.

See examples directory for more/full output examples or click the link in each example below.

## JSON - Examples of JSON output

There are three different JSON outputs available, six if you count adding -p/--pretty (as they stack) to make the output human readable nicer structured.

### json

Full JSON representation containing nested objects and arrays.

[Standard output](output-examples/example-format-json.json)

```json
[{"productName":"Elgato Key Light Air","firmwareVersion":"1.0.3","displayName":"Front  Right","numberOfLights":1,"lights":[{"on":0,"brightness":31,"temperature":179}],"device":"Elgato Key Light Air 0C2C","url":"http://192.168.0.132:9123","ipv4":"192.168.0.132", ...<omitted>..."settings":{"powerOnBehavior":1,"powerOnBrightness":20,"powerOnTemperature":213,"switchOnDurationMs":100,"switchOffDurationMs":300,"colorChangeDurationMs":100}}]
```

[Output with -p/--pretty option](output-examples/example-format-json-pretty.json)

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
    }
]
```

### simple

Simple JSON representation with an array (one object per light) with flattened objects. Flattened objects are using .(dot) notation where dots represents levels. Arrays are flattened to index numbers.

[Standard output](output-examples/example-format-simple.json)

```json
[{"productName":"Elgato Key Light Air","firmwareVersion":"1.0.3","displayName":"Front  Right","numberOfLights":1,"lights.0.on":0,"lights.0.brightness":31,"lights.0.temperature":179,"device":"Elgato Key Light Air 0C2C","url":"http://192.168.0.132:9123","ipv4":"192.168.0.132", ...<omittet>..."settings.powerOnBehavior":1,"settings.powerOnBrightness":20,"settings.powerOnTemperature":213,"settings.switchOnDurationMs":100,"settings.switchOffDurationMs":300,"settings.colorChangeDurationMs":100}]
```

[Output with -p/--pretty option](output-examples/example-format-simple-pretty.json)

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
    <omittet>
    ...
    "numberOfLights": 1,
    "lights.0.on": 0,
    "lights.0.brightness": 31,
    "lights.0.temperature": 179,
    "settings.powerOnBehavior": 1,
    "settings.powerOnBrightness": 20,
    "settings.powerOnTemperature": 213,
    "settings.switchOnDurationMs": 100,
    "settings.switchOffDurationMs": 300,
    "settings.colorChangeDurationMs": 100
  }
]
```

### flat

Completely flat JSON representation (single level object).
Flattened objects are using .(dot) notation where dots represents levels. Arrays are flattened to index numbers, including the first level array (that gets preserved in the simple format). Each light can be identified by the preceeding integer represeting the index of the light in the outer array.

[Standard output](output-examples/example-format-flat.json)

```json
{"0.productName":"Elgato Key Light Air","0.firmwareVersion":"1.0.3","0.displayName":"Front  Right","0.device":"Elgato Key Light Air 0C2C","0.url":"http://192.168.0.132:9123","0.ipv4":"192.168.0.132" ...<omittet>... ,"0.numberOfLights":1,"0.lights.0.on":0,"0.lights.0.brightness":31,"0.lights.0.temperature":179,"0.settings.powerOnBehavior":1,"0.settings.powerOnBrightness":20,"0.settings.powerOnTemperature":213,"0.settings.switchOnDurationMs":100,"0.settings.switchOffDurationMs":300,"0.settings.colorChangeDurationMs":100}
```

[Output with -p/--pretty option](output-examples/example-format-flat-pretty.json)

```json
{
  "0.productName": "Elgato Key Light Air",
  "0.firmwareVersion": "1.0.3",
  "0.displayName": "Front  Right",
  "0.device": "Elgato Key Light Air 0C2C",
  "0.url": "http://192.168.0.132:9123",
  "0.ipv4": "192.168.0.132",
  ...
  <omittet>
  ...
  "0.numberOfLights": 1,
  "0.lights.0.on": 0,
  "0.lights.0.brightness": 31,
  "0.lights.0.temperature": 179,
  "0.settings.powerOnBehavior": 1,
  "0.settings.powerOnBrightness": 20,
  "0.settings.powerOnTemperature": 213,
  "0.settings.switchOnDurationMs": 100,
  "0.settings.switchOffDurationMs": 300,
  "0.settings.colorChangeDurationMs": 100,
}
```

## csv - Examples of csv output

CSV representation has one row per light with headers. Outputing as CSV will look similar with or without the -p/--pretty option, the difference being the preservation of quoation marks for strings in the standard output.

[Standard output](output-examples/example-format-csv.csv)

```csv
"PRODUCTNAME","FIRMWAREVERSION","DISPLAYNAME","DEVICE","URL","IPV4","NUMBEROFLIGHTS","LIGHTS.0.ON","LIGHTS.0.BRIGHTNESS","LIGHTS.0.TEMPERATURE","SETTINGS.POWERONBEHAVIOR","SETTINGS.POWERONBRIGHTNESS","SETTINGS.POWERONTEMPERATURE","SETTINGS.SWITCHONDURATIONMS","SETTINGS.SWITCHOFFDURATIONMS","SETTINGS.COLORCHANGEDURATIONMS"
"Elgato Key Light Air","1.0.3","Front  Right","Elgato Key Light Air 0C2C","http://192.168.0.132:9123","192.168.0.132",1,0,31,179,1,20,213,100,300,100

```

[Output with -p/--pretty option](output-examples/example-format-csv-pretty.csv)

```csv
PRODUCTNAME,FIRMWAREVERSION,DISPLAYNAME,DEVICE,URL,IPV4,NUMBEROFLIGHTS,LIGHTS.0.ON,LIGHTS.0.BRIGHTNESS,LIGHTS.0.TEMPERATURE,SETTINGS.POWERONBEHAVIOR,SETTINGS.POWERONBRIGHTNESS,SETTINGS.POWERONTEMPERATURE,SETTINGS.SWITCHONDURATIONMS,SETTINGS.SWITCHOFFDURATIONMS,SETTINGS.COLORCHANGEDURATIONMS
Elgato Key Light Air,1.0.3,Front  Right,Elgato Key Light Air 0C2C,http://192.168.0.132:9123,192.168.0.132,1,0,31,179,1,20,213,100,300,100
```

## table - Examples of table output

Table representation has one row per light with headers. Flattened objects are using .(dot) notation where dots represents levels. Arrays are flattened to index numbers.

[Standard output](output-examples/example-format-table.txt)

```txt
PRODUCTNAME     DISPLAYNAME     DEVICE  IPV4    SETTINGS.POWERONBEHAVIOR        SETTINGS.POWERONBRIGHTNESS      SETTINGS.POWERONTEMPERATURE     SETTINGS.SWITCHONDURATIONMS     SETTINGS.SWITCHOFFDURATIONMS       SETTINGS.COLORCHANGEDURATIONMS
Elgato Key Light Air    Front  Right    Elgato Key Light Air 0C2C       192.168.0.132   1       20      213     100     300     100
```

[Output with -p/--pretty option](output-examples/example-format-table-pretty.txt)

```txt
PRODUCTNAME           DISPLAYNAME   DEVICE                     IPV4           SETTINGS.POWERONBEHAVIOR  SETTINGS.POWERONBRIGHTNESS  SETTINGS.POWERONTEMPERATURE  SETTINGS.SWITCHONDURATIONMS  SETTINGS.SWITCHOFFDURATIONMS  SETTINGS.COLORCHANGEDURATIONMS
Elgato Key Light Air  Front  Right  Elgato Key Light Air 0C2C  192.168.0.132  1                         20                          213                          100                          300                           100
```

## pair - Examples of key/value output

Key/value pair representation. Flattened objects are using .(dot) notation where dots represents levels. Arrays are flattened to index numbers.

[Standard output](output-examples/example-format-table.txt)

```txt
--------------
productName=Elgato Key Light Air
displayName=Front  Right
device=Elgato Key Light Air 0C2C
ipv4=192.168.0.132
lights.0.on=0
lights.0.brightness=31
lights.0.temperature=179
settings.powerOnBehavior=1
settings.powerOnBrightness=20
settings.powerOnTemperature=213
settings.switchOnDurationMs=100
settings.switchOffDurationMs=300
settings.colorChangeDurationMs=100

```

[Output with -p/--pretty option](output-examples/example-format-table-pretty.txt)

```txt
--------------                     
productName                     =  Elgato Key Light Air
displayName                     =  Front  Right
device                          =  Elgato Key Light Air 0C2C
ipv4                            =  192.168.0.132
lights.0.on                     =  0
lights.0.brightness             =  31
lights.0.temperature            =  179
settings.powerOnBehavior        =  1
settings.powerOnBrightness      =  20
settings.powerOnTemperature     =  213
settings.switchOnDurationMs     =  100
settings.switchOffDurationMs    =  300
settings.colorChangeDurationMs  =  100
```

## html - Examples of html table output

HTML table representation. Flattened objects are using .(dot) notation where dots represents levels. Arrays are flattened to index numbers. HTML table will be the same regardless of -p/--pretty option.

[Standard output](output-examples/example-format-html.html)

```txt
<table>
    <tr>
        <th>PRODUCTNAME</th>
        <th>DISPLAYNAME</th>
        <th>DEVICE</th>
        <th>IPV4</th>
        <th>SETTINGS.POWERONBEHAVIOR</th>
        <th>SETTINGS.POWERONBRIGHTNESS</th>
        <th>SETTINGS.POWERONTEMPERATURE</th>
        <th>SETTINGS.SWITCHONDURATIONMS</th>
        <th>SETTINGS.SWITCHOFFDURATIONMS</th>
        <th>SETTINGS.COLORCHANGEDURATIONMS</th>
    </tr>
    <tr>
        <td>Elgato Key Light Air</td>
        <td>Front Right</td>
        <td>Elgato Key Light Air 0C2C</td>
        <td>192.168.0.132</td>
        <td>1</td>
        <td>20</td>
        <td>213</td>
        <td>100</td>
        <td>300</td>
        <td>100</td>
    </tr>
</table>
```
