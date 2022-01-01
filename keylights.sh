#!/bin/bash
#set -x
set -Eeuo pipefail

trap destroy SIGINT SIGTERM ERR EXIT

# Settings
temp_file="/tmp/elgatokeylights"
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
icon="${script_dir}/assets/elgato.png"

# Declarations
declare -i silent=0
declare -i pretty=0
declare action="usage"
declare target=""
declare -A lights
declare lights_json
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
    rm "$temp_file" 2>/dev/null

    exit ${code}
}

usage() {
    cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-l] [-p] [-s] [-v] <action>

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

Available options:

-h, --help      Print this help and exit
-p, --pretty    Pretty print console output
-v, --verbose   Print script debug info
-s, --silent    Supress notifications
-t, --target    Only perform action on devices where value matches filter
EOF
    exit
}

parse_params() {
    # default values of variables set from params

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
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

    [[ ($silent -eq 1) && ($pretty -eq 1) ]] && die "Cannot use silent and pretty options simultaneously"

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
    declare json
    t=$(eval echo "'.[] | select($target)'")

    for l in "${!lights[@]}"; do
        json+="${lights[$l]},"
    done

    lights_json=$(echo "[${json%,}]" | jq -c "$t")
}

print_json() {
    # TODO: Evaluate adding jq filtering as filter argument
    if [[ $pretty -eq 1 ]]; then
        echo "$1" | jq '.'
    else
        echo "$1" | jq -c -M '.'
    fi

    exit 0
}

print_status() {
    die "To be implemented"
}

set_state() {
    new_state=$1
    die "To be implemented"
}

find_lights() {
    # Scan the network for Elgato devices
    avahi-browse -d local _elg._tcp --resolve -t | grep -v "^\+" >"$temp_file"

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

    cat "$temp_file" >tmp
    while read -r line; do

        # Gather information about the light
        if [[ ($line == =*) && ($line =~ IPv[46][[:space:]](.+)[[:space:]]_elg) ]]; then
            device=$(eval echo "${BASH_REMATCH[1]}") # eval to strip whitespace
        elif [[ $line =~ hostname.+\[(.+)\] ]]; then
            hostname=${BASH_REMATCH[1]}
        elif [[ $line =~ address.+\[(.+)\] ]]; then
            ip=${BASH_REMATCH[1]}
            [[ $ip =~ fe80 ]] && ipv6="$ip" || ipv4="$ip"
            ip=""
        elif [[ $line =~ port.+\[(.+)\] ]]; then
            port=${BASH_REMATCH[1]}
        elif [[ $line =~ txt.+\[(.+)\] ]]; then
            txt=$(eval echo "${BASH_REMATCH[1]}") # eval to strip single and double quotes

            if [[ $txt =~ mf=([^[[:space:]]*]*) ]]; then manufacturer=${BASH_REMATCH[1]}; fi
            if [[ $txt =~ id=([^[[:space:]]*]*) ]]; then mac=${BASH_REMATCH[1]}; fi
            if [[ $txt =~ md=.+[[:space:]]([^[[:space:]]*]*)[[:space:]]id= ]]; then sku=${BASH_REMATCH[1]}; fi

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

            # Store the light as json
            lights["$device"]=$(jq -n \
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
                --argjson info "$info" \
                '{device: $dev, manufacturer: $mf, hostname: $hn, url: $url, ipv4: $ipv4, ipv6: $ipv6, 
                    port: $port, mac: $mac, sku: $sku, light: $light, settings: $cfg, info: $info}')

            # Reset for next light as we are processing the last avahi line
            default_light_properties

        fi
    done <"$temp_file"
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
usage)
    usage
    ;;
list)
    print_json "${lights_json}"
    ;;
status)
    status
    ;;
on)
    set_state 1
    ;;
off)
    set_state 0
    ;;
esac
