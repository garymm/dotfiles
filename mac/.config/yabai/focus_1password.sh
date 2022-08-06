#!/usr/bin/env bash
set -o errexit
set -o pipefail

# Focus 1password's SSH key dialog.
# Maybe won't be needed, see https://1password.community/discussion/132033/

WINDOW_ID=$(yabai -m query --windows | jq -r '.[] | select(.app == "1Password" and .title == "") | .id')

if [[ -n "${WINDOW_ID}" ]]; then
   yabai -m window --focus "${WINDOW_ID}"
fi