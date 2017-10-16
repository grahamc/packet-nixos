#!/bin/sh

set -o pipefail
set -eu

ip="$1"
host="root@$ip"

_ssh() {
    ssh "$host" "$@" 2>&1 | sed "s/^/    /"
}

echo "Testing SSH:"
_ssh "true"

echo "Testing standard rebuild switch:"
_ssh "nixos-rebuild switch"
_ssh "true"

echo "Enabling nginx:"
scp ./test/nginx.nix "$host:/etc/nixos/test.nix"
scp -r ./test/nginx-root "$host:/etc/nixos/nginx-root/"

if ! _ssh "grep -q 'packet.nix test.nix' /etc/nixos/configuration.nix"; then
    _ssh "sed -i 's#packet.nix#packet.nix ./test.nix#' /etc/nixos/configuration.nix"
fi
_ssh "nixos-rebuild switch"
_ssh "true"

echo "Testing that nginx is ok:"
if curl -q "$ip" | grep -q 'hi :)'; then
    echo "ok"
else
    echo "not ok"
    exit 1
fi

echo "Issuing reboot..."
_ssh "reboot" || true

until _ssh "true"; do
    sleep 1
    printf "."
done
echo ""

echo "SSH is up"

echo "Rebuilding and rebooting once more"
_ssh "nixos-rebuild switch"
_ssh "reboot" || true

until _ssh "true"; do
    sleep 1
    printf "."
done
echo ""

echo "SSH is up"
