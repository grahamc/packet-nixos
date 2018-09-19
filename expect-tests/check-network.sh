#!/usr/bin/env nix-shell
#!nix-shell -p expect -i bash

echo hi

set -eu

. ./config.sh

ipv4_public=$1
target_ipv4_public=$TEST_IPV4_PUBLIC
target_ipv6_public=$TEST_IPV6_PUBLIC

sshopts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

retry() {
    for i in $(seq 1 10); do
        if "$@"; then
            return 0
        fi
        sleep 3
    done

    "$@"
}

check_network() {
    while ! ping -c1 "$ipv4_public"; do
        sleep 1
    done

    retry ssh $sshopts root@"$ipv4_public" true
    retry ssh $sshopts root@"$ipv4_public" curl https://ipv4.icanhazip.com
    retry ssh $sshopts root@"$ipv4_public" curl https://ipv6.icanhazip.com

    retry ssh $sshopts root@"$ipv4_public" ping -c1 "$target_ipv4_public"
    retry ssh $sshopts -A root@"$ipv4_public" ssh $sshopts root@"$target_ipv4_public" true

    retry ssh $sshopts root@"$ipv4_public" ping -c1 "$target_ipv6_public"
    retry ssh $sshopts -A root@"$ipv4_public" ssh $sshopts root@"$target_ipv6_public" true

    #retry ssh $sshopts root@"$ipv4_public" ping -c1 "$target_ipv4_private"
    #retry ssh $sshopts -A root@"$ipv4_public" ssh $sshopts root@"$target_ipv4_private" true

    retry ssh $sshopts root@"$ipv4_public" nix-shell -p speedtest-cli --run "speedtest"
}

check_network

echo allok
