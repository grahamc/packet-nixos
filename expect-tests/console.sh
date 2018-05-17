#!/bin/sh

set -ux

UUID=$1
REGION=$2

while true; do
    clear
    reset
    echo "reconnecting" >&2

    ssh "${UUID}@sos.${REGION}.packet.net"
    printf "\n\n\n\n\n"

    clear
    reset
    echo "disconnected"
done
