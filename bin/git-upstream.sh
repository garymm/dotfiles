#!/usr/bin/env bash

set -o errexit
set -o pipefail

if [[ $# -eq 0 ]]; then
    echo "Please provide a commit to cherry pick." >&2
    exit 1
fi

git fetch upstream master

git switch -c "cherry-pick-${1}" upstream/master
git cherry-pick "$@"
gh pr create --repo $(git remote get-url upstream)
