#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash

set -eu
set -o pipefail

. ./config.sh


function make_server() {
    PLAN="$1"
    URL="$2"
    terminate=$(TZ=UTC date --date='+1 hour' --iso-8601=seconds)

    json=$(cat <<EOF | jq -r .
      {
        "facility": [ "dfw2", "ewr1", "iad1", "atl1", "any" ],
        "plan": "$PLAN",
        "hostname": "test-instance",
        "description": "Test instance for $PLAN",
        "ipxe_script_url": "$URL",
        "operating_system": "7516833e-1b77-4611-93e9-d48225ca8b3c",
        "billing_cycle": "hourly",
        "termination_time": "${terminate}",
        "userdata": "",
	"spot_instance": true,
	"spot_price_max": 15.00,
        "locked": "false",
        "project_ssh_keys": [
        ],
        "user_ssh_keys": [
        ],
        "features": []
      }
EOF
        )

    echo "Creating server with: ${json}"

    curl --data "$json" \
         --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $PACKET_TOKEN" \
         --fail \
         "https://api.packet.net/projects/$PACKET_PROJECT_ID/devices" \
         | tee /dev/stderr \
         | jq -r .href
}

function fetch_info() {
    URL="$1"
    curl  --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $PACKET_TOKEN" \
         --fail \
         "https://api.packet.net/$URL" \
         | tee /dev/stderr \
         | jq -r .id,.facility.code,.ip_addresses[].address
}

function delete() {
    URL="$1"
    curl -X DELETE  --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $PACKET_TOKEN" \
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

while ! [ "$(fetch_info "$url" | wc -l)" -eq 5 ]; do
      echo "Waiting for addresses for $name"
      sleep 1;
done

fetch_info "$url" | xargs ./run.sh

sleep 10
