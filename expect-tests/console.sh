#!/bin/sh

set -u

UUID=$1
REGION=$2

while true; do
    echo "reconnecting" >&2

    ssh \
        -o StrictHostKeyChecking=no \
        -o UserKnownHostsFile=/dev/null \
        "${UUID}@sos.${REGION}.packet.net"
    printf "\n\n\n\n\n"

    echo "disconnected"
done
