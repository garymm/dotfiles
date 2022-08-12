#!/usr/bin/env bash

set -o errexit
set -o pipefail

GIT_ROOT=$(git rev-parse --show-toplevel)

DEST="${GIT_ROOT}/.git/hooks/prepare-commit-msg"

curl --output "${DEST}"  --location https://raw.githubusercontent.com/cac04/git-pair/master/prepare-commit-msg
chmod +x "${DEST}"
