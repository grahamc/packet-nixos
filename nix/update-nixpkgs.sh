#!/usr/bin/env sh

set -euxo pipefail

updateScript=$(nix-build --no-out-link ./nix/config.nix -A update)
$updateScript
