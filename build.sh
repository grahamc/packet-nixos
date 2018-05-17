#!/bin/sh

set -eux
set -o pipefail

. ./expect-tests/config.sh

buildHost=$BUILD_HOST_X86

tmpDir=$(mktemp -t -d nixos-rebuild-packet-pxe.XXXXXX)
SSHOPTS="${NIX_SSHOPTS:-} -o ControlMaster=auto -o ControlPath=$tmpDir/ssh-%n -o ControlPersist=60"

cleanup() {
    for ctrl in "$tmpDir"/ssh-*; do
        ssh -o ControlPath="$ctrl" -O exit dummyhost 2>/dev/null || true
    done
    rm -rf "$tmpDir"
}
trap cleanup EXIT

set -eux

if true; then
    arms=$(nix-build ./arm.nix --show-trace)
    NIX_SSHOPTS=$SSHOPTS nix-copy-closure --to "$buildHost" "$arms"
    drv=$(nix-instantiate ./all.nix --show-trace)
else
    drv=$(nix-instantiate ./x8664.nix --show-trace)
fi

NIX_SSHOPTS=$SSHOPTS nix-copy-closure --to "$buildHost" "$drv"
ssh $SSHOPTS "$buildHost" NIX_REMOTE=daemon nix-store --realize "$drv" -j 8 --add-root /var/www/result --indirect --keep-going
