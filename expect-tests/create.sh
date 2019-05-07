#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash

set -eu
set -o pipefail

. ./config.sh


function make_server() {
    PLAN="$1"
    URL="$2"

    reservation_id=""
    facility=""

    json=$(cat <<EOF | jq -r .
      {
        "plan": "$PLAN",
        "hostname": "test-instance",
        "description": "Test instance for $PLAN",
        "ipxe_script_url": "$URL",
        "operating_system": "7516833e-1b77-4611-93e9-d48225ca8b3c",
        "billing_cycle": "hourly",
        "userdata": "",
        "locked": "false",
        "project_ssh_keys": [
        ],
        "user_ssh_keys": [
        ],
        "features": []
      }
EOF
        )


    if [ "x$reservation_id" == "x" ]; then
        terminate=$(TZ=UTC date --date='+3 hour' --iso-8601=seconds)
        json=$(jq -s '$json * $extra' --argjson json "$json" --argjson extra '
        {
            "termination_time": "'"$terminate"'",
            "spot_instance": true,
            "spot_price_max": 15.00
        }
        ' < /dev/null)
    else
        json=$(jq -s '$json * $extra' --argjson json "$json" --argjson extra '
        {
            "hardware_reservation_id": "'"$reservation_id"'"
        }
        ' < /dev/null)
    fi

    if [ "x$facility" == "x" ]; then
        json=$(jq -s '$json * $extra' --argjson json "$json" --argjson extra '
        {
            "facility": [ "dfw2", "ewr1", "sjc1", "iad1", "atl1", "any" ]
        }
        ' < /dev/null)
    else

        json=$(jq -s '$json * $extra' --argjson json "$json" --argjson extra '
        {
            "facility": "'"$facility"'"
        }
        ' < /dev/null)
    fi

    echo "Creating server with: ${json}" >&2

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
   pxe_url="$PXE_ROOT/c1.large.arm/netboot.ipxe"
else
   pxe_url="$PXE_ROOT/$name/netboot.ipxe"
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
