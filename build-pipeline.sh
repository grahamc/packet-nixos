#!/bin/sh

set -eux

mkdir -p ./.buildkite

STAGE="${1:-build}"

nix-build ./instance-types.nix \
          --out-link ./.buildkite/pipeline.yml \
          -A "$STAGE"
