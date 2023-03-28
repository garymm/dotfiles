#!/bin/bash

set -o errexit
set -o pipefail

# Move environment variables from tmux into shell
if [[ -n "$TMUX" ]]; then
    prefix_len=$(expr length "VSCODE_IPC_HOOK_CLI=")
    assignment=$(tmux show-environment | grep ^VSCODE_IPC_HOOK_CLI)
    if [[ -n "${assignment}" ]]; then
        export VSCODE_IPC_HOOK_CLI="${assignment:${prefix_len}}"
        prefix_len=$(expr length "PATH=")
        assignment=$(tmux show-environment | grep ^PATH)
        export PATH="${assignment:${prefix_len}}"
    fi
fi

if [[ -z "$(which code)" ]]; then
    if [[ $(uname) == "Darwin" ]]; then
        if [[ $(uname -m) == "arm64" ]]; then
            BREW_PREFIX=/opt/homebrew
        else
            BREW_PREFIX=/usr/local
        fi
        export PATH="${BREW_PREFIX}/bin:$PATH"
    fi
fi

# Try to find VS Code remote session without being inside its terminal.
if [[ -z "$(which code)" && $(uname) == "Linux" ]]; then
    # -t to see newest file first. Connecting to older ones might fail.
    for f in $(ls -t /proc/*/environ); do
      # Skip unreadable files.
      if [[ -r $f && -n $(grep 'VSCODE_IPC_HOOK_CLI=' $f) ]]; then
        while IFS= read -r -d $'\0' assignment; do
            if [[ $assignment == VSCODE_IPC_HOOK_CLI=* ]]; then
                prefix_len=$(expr length "VSCODE_IPC_HOOK_CLI=")
                export VSCODE_IPC_HOOK_CLI="${assignment:${prefix_len}}"
            fi
            if [[ $assignment == PATH=* ]]; then
                prefix_len=$(expr length "PATH=")
                export PATH="${assignment:${prefix_len}}"
            fi
        done < "${f}"
        if [[ -n "${VSCODE_IPC_HOOK_CLI}" ]]; then
            break
        fi
      fi
    done
fi

if [[ -z "$(which code)" ]]; then
    vim "$@"
else
    code --wait "$@"
fi
