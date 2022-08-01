#!/bin/bash

set -o errexit
set -o pipefail

# Move environment variables from tmux into shell
if [[ -n "$TMUX" ]]; then
    prefix_len=$(expr length "VSCODE_IPC_HOOK_CLI=")
    assignment=$(tmux show-environment | grep ^VSCODE_IPC_HOOK_CLI)
    export VSCODE_IPC_HOOK_CLI="${assignment:${prefix_len}}"
    prefix_len=$(expr length "PATH=")
    assignment=$(tmux show-environment | grep ^PATH)
    export PATH="${assignment:${prefix_len}}"
fi

if [[ -z "$(which code)" ]]; then
    if [[ $(uname) -eq "Darwin" ]]; then
        if [[ $(uname -m) -eq "arm64" ]]; then
            BREW_PREFIX=/opt/homebrew
        else
            BREW_PREFIX=/usr/local
        fi
        export PATH="${BREW_PREFIX}/bin:$PATH"
    fi
fi
code --wait "$@"
