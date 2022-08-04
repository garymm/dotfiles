#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

readonly N_DISPLAYS=$(yabai -m query --displays | jq length)
readonly CUR_DISPLAY=$(yabai -m query --displays --display | jq '.index')
readonly N_SPACES=$(yabai -m query --spaces | jq 'map(select(."is-native-fullscreen" == false)) | length')
readonly CUR_SPACE=$(yabai -m query --spaces --space | jq '.index')

function create_up_to_n_spaces() {
    local -r n="${1}"
    if [[ "${n}" -le "${N_SPACES}" ]]; then
        return
    fi
    for ((i=1; i <= n; i++)); do
        if [[ "${i}" -gt "${N_SPACES}" ]]; then
            yabai -m space --create
        fi
    done
    # Loop backwards to void the case where a display has
    # only 1 space on it and then we're unable to move it.
    for ((i=n; i >= 1; i--)); do
        local target_disp="$(display_for_space "${i}" "${n}")"
        local actual_disp="$(yabai -m query --spaces --space ${i} | jq .display)"
        if [[ "${target_disp}" -ne "${actual_disp}" ]]; then
            yabai -m space "${i}" --display "${target_disp}"
        fi
    done
}

function display_for_space() {
    local -r space="${1}"
    local n_spaces=${2:-N_SPACES}
    local -r divisor=$((n_spaces / N_DISPLAYS))
    # divide with ceiling
    echo "$(( ((space + divisor - 1)) / divisor))"
}

function init() {
    local -r n="${1}"
    create_up_to_n_spaces "$((n * N_DISPLAYS))"
    yabai -m space --focus "${CUR_SPACE}"
}

function focus_offset() {
    # TODO: Handle full screen properly.
    if [[ "true" == $(yabai -m query --spaces --space | jq '."is-native-fullscreen"') ]]; then
        return
    fi
    local -r offset="${1}"
    local -r cur_space_on_disp1=$((CUR_SPACE - (CUR_DISPLAY-1) * N_SPACES / N_DISPLAYS))
    if [[ "${offset}" == -1 && "${cur_space_on_disp1}" == 1 ]]; then
        return 0
    elif [[ "${offset}" == 1 && "${cur_space_on_disp1}" == $((N_SPACES / N_DISPLAYS)) ]]; then
        return 0
    fi
    local target_space_on_disp1=$((cur_space_on_disp1 + offset))
    focus "${target_space_on_disp1}"
}

function focus() {
    local -r target_space_on_disp1="${1}"
    for ((i=1; i <= N_DISPLAYS; i++)); do
        local target_space=$((target_space_on_disp1 + (i - 1) * N_SPACES / N_DISPLAYS))
        yabai -m space --focus "${target_space}"
    done
    yabai -m display --focus "${CUR_DISPLAY}"
}

function send_to() {
    # TODO: Handle full screen properly.
    local -r target_space_on_disp1="${1}"
    local target_space=$((target_space_on_disp1 + (CUR_DISPLAY - 1) * N_SPACES / N_DISPLAYS))
    yabai -m window --space "${target_space}"
}

readonly CMD="${1}"

if [[ "${CMD}" == "init" ]]; then
    init "${2}"
    exit 0
elif [[ "${CMD}" == "focus-left" ]]; then
    focus_offset -1
    exit 0
elif [[ "${CMD}" == "focus-right" ]]; then
    focus_offset 1
    exit 0
elif [[ "${CMD}" == "focus" ]]; then
    focus "${2}"
    exit 0
elif [[ "${CMD}" == "send" ]]; then
    send_to "${2}"
    exit 0
fi