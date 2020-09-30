#!/bin/bash

set -o errexit
set -o pipefail

# Move environment variables from tmux into shell
if [ -n "$TMUX" ]; then
    prefix_len=$(expr length "VSCODE_IPC_HOOK_CLI=")
    assignment=$(tmux show-environment | grep ^VSCODE_IPC_HOOK_CLI)
    export VSCODE_IPC_HOOK_CLI="${assignment:${prefix_len}}"
    prefix_len=$(expr length "PATH=")
    assignment=$(tmux show-environment | grep ^PATH)
    export PATH="${assignment:${prefix_len}}"

fi

code --wait "$@"
