#!/usr/bin/env bash

# 1. Fetches one of {master,main,$1} from origin
# 2. Resets local branch to origin
# 3. Rebases current branch on top of the fetched branch

set -o errexit
set -o pipefail

if [[ -n $(git status --porcelain) ]]; then
    echo "git status is not clean. Please commit or stash your changes."
    exit 1
fi

CURRENT_BRANCH=$(git branch --show-current)

if [[ -z "${CURRENT_BRANCH}" ]]; then
    echo "Could not determine current branch."
    exit 1
fi

if git rev-parse --verify main >/dev/null 2>&1; then
    DEFAULT_ONTO_BRANCH="main"
else
    DEFAULT_ONTO_BRANCH="master"
fi

if [[ -n "${1}" ]]; then
    ONTO_BRANCH="${1}"
else
    ONTO_BRANCH="${DEFAULT_ONTO_BRANCH}"
fi

git switch "${ONTO_BRANCH}"
git fetch origin "${ONTO_BRANCH}"
git reset --hard "origin/${ONTO_BRANCH}"
git switch "${CURRENT_BRANCH}"
git rebase "${ONTO_BRANCH}"
