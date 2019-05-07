#!/bin/sh

set -eu
set -o pipefail

. ./expect-tests/config.sh

buildHost=root@$PXE_BUILD_HOST

set -x

drv=$(realpath $(time nix-instantiate ./all.nix --show-trace --add-root ./result.drv --indirect))

export NIX_SSHOPTS="-o UserKnownHostsFile=./pxe-known-host"
nix-copy-closure --to "$buildHost" "$drv"
ssh $NIX_SSHOPTS "$buildHost" NIX_REMOTE=daemon nix-store --realize "$drv" --add-root /var/www/result --indirect --keep-going
