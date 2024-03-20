#!/usr/bin/env bash
set -o errexit
set -o pipefail

# This script is usually in ~/bin. Check if ~/bin/code is there.
if [[ -z "$(which code)" ]]; then
    SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
    export PATH="${SCRIPT_DIR}:${PATH}"
fi

for CODE in cursor code code-insiders; do
    if [[ -n "$(which ${CODE})" ]]; then
        "${CODE}" --wait "$@"
        exit $?
    fi
done

vim "$@"
