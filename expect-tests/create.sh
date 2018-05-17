#!/usr/bin/env nix-shell
#!nix-shell -p curl -p jq -i bash

set -eux
set -o pipefail

. ./config.sh

function make_server() {
    REGION=$1
    PLAN="$2"
    URL="$3"
    set -x
    curl -v --data '{
        "facility": "'"$REGION"'",
        "plan": "'"$PLAN"'",
        "hostname": "test-instance",
        "description": "Test instance for $TYPE",
        "ipxe_script_url": "'"$URL"'",
        "operating_system": "7516833e-1b77-4611-93e9-d48225ca8b3c",
        "billing_cycle": "hourly",
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
         "https://api.packet.net/projects/$PROJECT/devices" \
         | tee /dev/stderr \
         | jq -r .href
}

function fetch_info() {
    URL="$1"
    set -x
    curl  --header 'Accept: application/json' \
         --header 'Content-Type: application/json' \
         --header "X-Auth-Token: $token" \
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

region=ewr1
name=c2.medium.x86
name=c1.small.x86
name=c1.xlarge.x86
name=m1.xlarge.x86
name=s1.large.x86
name=t1.small.x86
name=x1.small.x86 region=atl1
name=m2.xlarge.x86 region=ams1
url=$(make_server $region $name "$IPXE_ROOT/$name/netboot.ipxe")

while ! [ "$(fetch_info "$url" | wc -l)" -eq 5 ]; do sleep 1; done

fetch_info "$url" | xargs ./run.sh

sleep 60

delete "$url"