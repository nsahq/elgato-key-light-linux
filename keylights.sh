#!/bin/bash
set -Eeuo pipefail

trap destroy SIGINT SIGTERM ERR EXIT

# Settings
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
icon="${script_dir}/assets/elgato.png"

# Declarations
declare -i silent=0
declare -i pretty=0
declare action="usage"
declare target='.'
declare format="json"
declare -A lights
declare lights_json
declare flat_json
declare call='curl --silent --show-error --location --header "Accept: application/json" --request'
declare devices="/elgato/lights"
declare accessory_info="/elgato/accessory-info"
declare settings="/elgato/lights/settings"

if [ ! -r "${icon}" ]; then icon=sunny; fi

notify() {
    if [ $silent -eq 0 ]; then
        notify-send -i "$icon" "Key Light Controller" "$1"
    fi
}

die() {
    echo >&2 -e "${1-}"
    exit "${2-1}"
}

destroy() {
    code=$?

    exit ${code}
}

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-f <value>] [-l] [-p] [-s] [-t <value>][-v] [--<option>] [--<option> <value>] <action>

Elgato Lights controller. Works for Key Light and Key Light Air.

Available actions:
    list        List available lights
    status      Get state of lights
    on          Turn all lights on
    off         Turn all lights off
    temperature  Set temperature level (260-470)
    brightness  Set brightness level (0-100)
    increase    Increases brightness by 10
    decrease    Decreases brightness by 10

Available formats:
    json        Renders output as JSON (default)
    flat        Renders output as flattened JSON with .(dot) notation JSON (default)
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
EOF
    exit
}

parse_params() {
    # default values of variables set from params

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -f | --format)
            format="${2-}"
            shift
            ;;
        -p | --pretty) pretty=1 ;;
        -v | --verbose) set -x ;;
        -s | --silent) silent=1 ;;
        -t | --target)
            target="${2-}"
            shift
            ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    # check required params and arguments
    declare -A actions=([help]=1 [list]=1 [status]=1 [on]=1 [off]=1)
    [[ ${#args[@]} -ne 1 ]] && die "Incorrect argument count"

    #[[ ($silent -eq 1) && ($pretty -eq 1) ]] && die "Cannot use silent and pretty options simultaneously"

    [[ -n "${actions[${args[0]}]}" ]] && action="${args[0]}"

    return 0
}

dependencies() {
    for var in "$@"; do
        if ! command -v $var &>/dev/null; then
            die "Dependency $var was not found, please install and try again"
        fi
    done
}

default_light_properties() {
    # Default values for json type enforcement
    device="N/A"
    hostname="N/A"
    manufacturer="N/A"
    ipv4="N/A"
    ipv6="N/A"
    port=0
    mac="N/A"
    sku="N/A"
    cfg="{}"
    url="{}"
    info="{}"
    light="{}"

}

produce_json() {
    t=$(eval echo "'[.[] | select($target)]'")

    lights_json=$(echo "${lights[@]}" | jq -c -s "$t")
}

output() {
    data=${1-}
    type=${2-"$format"}

    # Mange user requested output format
    case $format in
    json | flat) print_json "$data" ;;
    table) print_json "$data" ;;
    csv) print_csv "$data" ;;
    pair) print_pair "$data" ;;
    html) print_html "$data" ;;
    -?*) die "Unknown output format (-f/--format): $type" ;;
    esac
}

print_json() {
    # TODO: Evaluate adding jq filtering as filter argument
    query=""

    # Deconstruct json and assemble in flattened with .(dot) notation
    if [[ $format == "flat" ]]; then
        query='reduce ( tostream | select(length==2) | .[0] |= [join(".")] ) as [$p,$v] ({}; setpath($p; $v))'
    else
        query='.'
    fi

    # Manage pretty printing
    if [[ $pretty -eq 1 ]]; then
        echo "${1-}" | jq "$query"
    else
        echo "${1-}" | jq -c -M "$query"
    fi

    exit 0
}

print_table() {
    bold=$(tput bold)
    normal=$(tput sgr0)
    message='
    
'
    die "To be implemented"
}

set_state() {
    new_state=$1
    die "To be implemented"
}

find_lights() {
    # Scan the network for Elgato devices
    declare -a avahi
    readarray -t avahi < <(avahi-browse -d local _elg._tcp --resolve -t -p | grep -v "^\+")

    declare device
    declare hostname
    declare manufacturer
    declare ipv4
    declare ipv6
    declare -i port
    declare mac
    declare sku
    declare cfg
    declare url
    declare info
    declare light
    default_light_properties

    for l in "${avahi[@]}"; do
        IFS=';' read -ra data <<<"$l" # split line into array

        # Gather information about the light
        device=$(echo "${data[3]}" | sed -e 's/\\032/ /g') # fix avahi output
        hostname=${data[6]}
        [[ ${data[7]} =~ fe80 ]] && ipv6=${data[7]} || ipv4=${data[7]}
        port=${data[8]}
        txt=$(eval echo "${data[9]}") # eval to strip quotes
        [[ $txt =~ mf=([^[[:space:]]*]*) ]] && manufacturer=${BASH_REMATCH[1]}
        [[ $txt =~ id=([^[[:space:]]*]*) ]] && mac=${BASH_REMATCH[1]}
        [[ $txt =~ md=.+[[:space:]]([^[[:space:]]*]*)[[:space:]]id= ]] && sku=${BASH_REMATCH[1]}

        # Get information from the light
        url="http://$ipv4:$port"

        declare protocol="--ipv4"
        if [[ $ipv4 == "N/A" ]]; then
            # Workaround: Ignoring ipv6 as Elgato miss-announces addressing and is not accepting requests
            # properly for v6. Will not change to filter only on ipv4 from avahi, as that can cause us to only end
            # up with an ipv6 address even though it was announced as ipv4, which in turn means we cannot communicate.
            continue
            # Remove above and uncomment below if a future update fixes ipv6 announcement and requests
            #protocol="--ipv6"
            #url="http://[$ip]:$port"
        fi

        cfg=$(eval "${call} GET $protocol ${url}${settings}") >/dev/null
        info=$(eval "${call} GET $protocol ${url}${accessory_info}") >/dev/null
        light=$(eval "${call} GET $protocol ${url}${devices}") >/dev/null

        json=$(jq -n \
            --arg dev "$device" \
            --arg hn "$hostname" \
            --arg ipv4 "$ipv4" \
            --arg ipv6 "$ipv6" \
            --argjson port "$port" \
            --arg mf "$manufacturer" \
            --arg mac "$mac" \
            --arg sku "$sku" \
            --arg url "$url" \
            --argjson light "$light" \
            --argjson cfg "$cfg" \
            '{device: $dev, manufacturer: $mf, hostname: $hn, url: $url, ipv4: $ipv4, ipv6: $ipv6, 
                port: $port, mac: $mac, sku: $sku, light: $light, settings: $cfg}')

        # Store the light as json
        lights["$device"]=$(echo "$info $json" | jq -s '. | add')

        # Reset for next light as we are processing the last avahi line
        default_light_properties

    done
}

# Manage user parameters
parse_params "$@"

# Make sure dependencies are installed
dependencies avahi-browse curl notify-send jq

find_lights

# Fail if we cannot find lights
[[ ${#lights[@]} -eq 0 ]] && die "No lights found" 2

produce_json

# Dispatch actions
case $action in
usage) usage ;;
list) output "${lights_json}" ;;
status) status ;;
on) set_state 1 ;;
off) set_state 0 ;;
-?*) die "Unknown action" ;;
esac
