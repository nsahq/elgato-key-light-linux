#!/bin/bash
#set -x
set -o nounset
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
declare -A lights
declare lights_json
declare call="curl --silent --show-error --location --header 'Accept: application/json' --request"
declare devices="/elgato/lights"
declare accessory_info="/elgato/accessory-info"
declare settings="/elgato/lights/settings"

if [ ! -r "${icon}" ]; then icon=sunny; fi

notify() {
    echo "mm"
    if [ $silent -eq 0 ]; then
        notify-send -i "$icon" "Key Light Controller" "$1"
    fi
}

error() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1} # default exit status 1
    error "$msg"
    exit "$code"
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
-f, --flag      Some flag description
-s, --silent    Supress notifications
EOF
    exit
}

parse_params() {
    # default values of variables set from params

    while :; do
        case "${1-}" in
        -h | --help) usage ;;
        -p | --pretty) pretty=1;;
        -v | --verbose) set -x ;;
        -s | --silent) silent=1 ;;
        -?*) die "Unknown option: $1" ;;
        *) break ;;
        esac
        shift
    done

    args=("$@")

    # check required params and arguments
    declare -A actions=([help]=1 [list]=1)
    #[[ -z "${param-}" ]] && die "Missing required parameter: param"
    [[ ${#args[@]} -ne 1 ]] && die "Incorrect action count, 1 allowed"
    
    [[ -n "${actions[${args[0]}]}" ]] && action="${args[0]}"
    
    return 0
}

dependencies() {
    for var in "$@"; do
        if ! command -v $var &>/dev/null; then
            error "Dependency $var was not found, please install and try again"
        fi
    done

}

produce_json() {
    declare json
    for l in "${!lights[@]}"; do
        json+="${lights[$l]},"
    done

    lights_json="[${json%,}]"
}

print_json() {
    if [[ $pretty -eq 1 ]]; then
        echo "$1"|jq '.' 
    else
        echo "$1"|jq -c -M '.'
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

    # Declaration for json type forcing
    declare device="N/A"
    declare hostname="N/A"
    declare manufacturer="N/A"
    declare ip="N/A"
    declare -i port=0
    declare mac="N/A"
    declare sku="N/A"

    cat "$temp_file" > tmp
    while read -r line; do

        # Gather information about the light
        if [[ ($line == =*) && ($line =~ IPv4[[:space:]](.+)[[:space:]]_elg) ]]; then
            device=$(eval echo "${BASH_REMATCH[1]}") # eval to strip whitespace
        elif [[ $line =~ hostname.+\[(.+)\] ]]; then hostname=${BASH_REMATCH[1]};
        elif [[ $line =~ address.+\[(.+)\] ]]; then ip=${BASH_REMATCH[1]};
        elif [[ $line =~ port.+\[(.+)\] ]]; then port=${BASH_REMATCH[1]};
        elif [[ $line =~ txt.+\[(.+)\] ]]; then
            txt=$(eval echo "${BASH_REMATCH[1]}") # eval to strip single and double quotes

            if [[ $txt =~ mf=([^[[:space:]]*]*) ]]; then manufacturer=${BASH_REMATCH[1]}; fi
            if [[ $txt =~ id=([^[[:space:]]*]*) ]]; then mac=${BASH_REMATCH[1]}; fi
            if [[ $txt =~ md=.+[[:space:]]([^[[:space:]]*]*)[[:space:]]id= ]]; then sku=${BASH_REMATCH[1]}; fi

            
            # Get information from the light
            declare {cfg,url,info,light}="{}"
            if [[ ! (-z $ip) && ! (-z $port) ]]; then
                url="http://$ip:$port"
                #echo "${call} GET ${url}${settings}"
                cfg=$(eval "${call} GET ${url}${settings}") > /dev/null
                #echo "${call} GET ${url}${accessory_info}"
                info=$(eval "${call} GET ${url}${accessory_info}") > /dev/null
                #echo "${call} GET ${url}${devices}"
                light=$(eval "${call} GET ${url}${devices}") > /dev/null
            fi
            # Store the light as json
            lights["$ip"]=$( jq -n \
                    --arg dev "$device" \
                    --arg hn "$hostname" \
                    --arg ip "$ip" \
                    --arg port "$port" \
                    --arg mf "$manufacturer" \
                    --arg mac "$mac" \
                    --arg sku "$sku" \
                    --arg url "$url" \
                    --argjson light "$light" \
                    --argjson cfg "$cfg" \
                    --argjson info "$info" \
                    '{device: $dev, manufacturer: $mf, hostname: $hn, url: $url, ip: $ip, 
                    port: $port, mac: $mac, sku: $sku, light: $light, settings: $cfg, info: $info}' )
            
            # Reset for next light
            declare {device,hostname,manufacturer,url,ip,mac,protocol,sku,cfg}="N/A"
            declare port=0
        fi
    done <"$temp_file"
    
    rm "$temp_file" 2>/dev/null
}

# Manage user parameters
parse_params "$@"

# Make sure dependencies are installed
dependencies avahi-browse curl notify-send jq

find_lights

# Fail if we cannot find lights
[[ ${#lights[@]} -eq 0 ]] && error "No lights found" 1

produce_json

# Dispatch actions
[[ $action == "usage" ]] && usage
[[ $action == "list" ]] && print_json "${lights_json}"
[[ $action == "status" ]] && status
[[ $action == "on" ]] && set_state 1
[[ $action == "off" ]] && set_state 0



# Manage printing (parameter -l/--list specicified)







