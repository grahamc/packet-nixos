#!/bin/sh

set -eux

mkdir -p ./.buildkite
nix-build ./instance-types.nix \
          --out-link ./.buildkite/pipeline.yml
