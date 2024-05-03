#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# https://stackoverflow.com/questions/36428948/how-can-i-delete-all-local-branches-which-would-result-in-no-changes-if-merged-i#comment61667480_36428948
git fetch --prune
git branch -D $(git branch -vv | grep gone | cut -d " " -f 3)
