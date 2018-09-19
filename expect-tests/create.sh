#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash

set -eu
set -o pipefail

. ./config.sh

#,
#        "userdata": "#!nix\n{ pkgs, ... }: { environment.systemPackages = [ pkgs.hello ]; "

function make_server() {
    PLAN="$1"
    URL="$2"
    terminate=$(TZ=UTC date --date='+1 hour' --iso-8601=seconds)

    # "ipxe_script_url": "'"$URL"'",
    # "operating_system": "7516833e-1b77-4611-93e9-d48225ca8b3c",
    #18.03:
    #
    curl -v --data '{
        "facility": [ "ewr1", "iad1", "atl1", "any" ],
        "plan": "'"$PLAN"'",
        "hostname": "test-instance",
        "description": "Test instance for $TYPE",
        "operating_system": "97025afd-97d8-4459-bdb6-d3daa98ea162",
        "billing_cycle": "hourly",
	"spot_instance": true,
	"spot_price_max": '5.00',
        "termination_time": "'"${terminate}"'",
        "userdata": "",
        "locked": "false",
        "project_ssh_keys": [
        ],
        "user_ssh_keys": [
        ],
        "features": [
        ]
        }
    ' --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
         --fail \
         "https://api.packet.net/projects/$PROJECT/devices" \
         | tee /dev/stderr \
         | jq -r .href
}

function fetch_info() {
    URL="$1"
    curl  --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
         --fail \
         "https://api.packet.net/$URL" \
         | tee /dev/stderr \
         | jq -r .id,.facility.code,.ip_addresses[].address
}

function delete() {
    URL="$1"
    curl -X DELETE  --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
         "https://api.packet.net/$URL" \
    | tee /dev/stderr
}


name="$1"

if [ "$name" == "c1.large.arm.xda" ]; then
   pxe_url="$IPXE_ROOT/c1.large.arm/netboot.ipxe"
#elif [ "$name" == "c2.medium.x86" ]; then
#   pxe_url="http://147.75.197.111/c2med/netboot.ipxe"
else
   pxe_url="$IPXE_ROOT/$name/netboot.ipxe"
fi

url=$(make_server "$name" "$pxe_url")

cleanup() {
          delete "$url"
}
trap cleanup EXIT

while ! [ "$(fetch_info "$url" | wc -l)" -eq 5 ]; do sleep 1; done

fetch_info "$url" | xargs ./run.sh

sleep 10
