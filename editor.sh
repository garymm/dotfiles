#!/bin/bash

set -o errexit
set -o pipefail

# Move environment variables from tmux into shell
if [ -n "$TMUX" ]; then
    export $(tmux show-environment | grep ^VSCODE_IPC_HOOK_CLI)
    export $(tmux show-environment | grep ^PATH)
fi

code --wait "$@"
