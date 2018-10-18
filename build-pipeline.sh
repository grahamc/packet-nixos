#!/bin/sh

set -eux

stat /etc/packet-nixos-config
stat /run/keys/packet-nixos-config

mkdir -p ./.buildkite
nix-build ./instance-types.nix \
          --out-link ./.buildkite/pipeline.yml
