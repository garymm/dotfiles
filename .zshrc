# Path to your oh-my-zsh installation.
export ZSH=${HOME}/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="garymm"

COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  bazel
  colored-man-pages
  direnv
  fzf
  gitfast
  zsh-interactive-cd
)

# Seems required for kitty, but probably doesn't hurt otherwise.
# https://apple.stackexchange.com/q/269324/34090
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# https://unix.stackexchange.com/a/62599/88047
typeset -U path PATH

if [[ $(uname) -eq "Darwin" ]]; then
  if [[ $(uname -m) -eq "arm64" ]]; then
    BREW_PREFIX=/opt/homebrew
  else
    BREW_PREFIX=/usr/local
  fi
  export FZF_BASE=${BREW_PREFIX}/opt/fzf/
  LESSPIPE="${BREW_PREFIX}/bin/src-hilite-lesspipe.sh"
  # Use brew's ruby gems
  path=("${BREW_PREFIX}/lib/ruby/gems/3.1.0/bin" "$path[@]")
  # Use brew binaries by default
  path=("${BREW_PREFIX}/bin" "$path[@]")
else
  # On Linux I install from source, see setup-debian.sh
  export FZF_BASE="${HOME}/.fzf"
  LESSPIPE="/usr/share/source-highlight/src-hilite-lesspipe.sh"
  plugins+=(tmux docker)
fi

source $ZSH/oh-my-zsh.sh

# User configuration

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    path=("$HOME/bin" "$path[@]")
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    path=("$HOME/.local/bin" "$path[@]")
fi

if [[ -z "${SSH_CLIENT}" || "${TERM_PROGRAM}" -eq "vscode" ]]; then
  export EDITOR="${HOME}/bin/editor.sh"
else
  export EDITOR="vim"
fi

alias ls='ls -FG' # G is color, F is trailing slashes, etc.
alias sed='sed --regexp-extended'
alias curl='curl --location' # follow redirects
export LESSOPEN="| ${LESSPIPE} %s"
export LESS=' --LONG-PROMPT --RAW-CONTROL-CHARS --quit-on-intr '
# https://superuser.com/a/1321991
export MANPAGER='less +Gg'

# fbr - checkout git branch
fbr() {
   local branches branch
   branches=$(git branch -vv) &&
   branch=$(echo "$branches" | fzf +m) &&
   git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# fuzzy match and then run VSCode
fcod() {
  local files
  local FZF
  if [[ -n "$TMUX" ]]; then
    FZF=fzf-tmux
  else
    FZF=fzf
  fi
  IFS=$'\n' files=($("${FZF}" --query="$1" --multi --select-1 --exit-0))
  [[ -n "$files" ]] && code "${files[@]}"
}

# Create a new branch tracking origin
function gnb {
  git switch --create "$@" master
  git branch --set-upstream-to "origin/$@"
}

function echoerr() {
  echo "$@" 1>&2
}

# VSCode remote workflow sets PATH when connecting to the server.
# But existing shells in tmux windows don't get the updated PATH, unless we
# run this to move environment variables from tmux into the shell.

function update_path {
  IFS=':' read -r -A input_array <<< "${1}"
  local new_vscode_server_bin=""
  for element in "${input_array[@]}"; do
    if [[ "${element}" == *.vscode-server/bin* ]]; then
      new_vscode_server_bin="${element}"
    fi
  done
  if [[ -z "${new_vscode_server_bin}" ]]; then
    echoerr "input did not contain vscode-server/bin"
    return 1
  fi

  local replaced_vscode_server_bin=0

  IFS=':' read -r -A path_array <<< "${PATH}"
  for (( i = 1; i <= ${#path_array}; i++ )) do
    if [[ "${path_array[i]}" == *.vscode-server/bin* ]]; then
      if [ ${replaced_vscode_server_bin} -eq 0 ]; then
        path_array[i]="${new_vscode_server_bin}"
        replaced_vscode_server_bin=1
      else
        path_array[i]=()
      fi
    fi
  done

  local with_leading_colon=$(printf ":%s" "${path_array[@]}")
  # strip leading colon
  echo "${with_leading_colon:1}"
}

if [ -n "$TMUX" ]; then
  function refresh_env {
    IFS=$'\n' VARS=($(tmux show-environment | grep -v '^-'))
    for VAR in $VARS; do
      local path_prefix_len=$(expr match "$VAR" '^PATH=')
      if [ ${path_prefix_len} -gt 0 ]; then
        export PATH=$(update_path "${VAR:${path_prefix_len}}")
      else
        export $VAR
      fi
    done
  }
  # Ensures PATH can find vscode
  alias code='refresh_env && \code'
fi

mkdir -p /tmp/ssh-master

# https://sw.kovidgoyal.net/kitty/kittens/ssh/
SSH_BIN=$(which -a ssh | grep '^/')

function ssh {
  local PREFIX=""
  local SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
  if [[ $(uname) -eq "Darwin" ]] && [[ -S "${SOCK}" ]]; then
    PREFIX="SSH_AUTH_SOCK=${SOCK}"
  fi
  if [[ "${TERM}" == "xterm-kitty" ]]; then
    env "${PREFIX}" kitty +kitten ssh "$@"
  else
    env "${PREFIX}" "${SSH_BIN}" "$@"
  fi
}

# https://github.com/kovidgoyal/kitty/issues/838#issuecomment-770328902
if [[ "${TERM}" == "xterm-kitty" ]]; then
  bindkey "\e[1;3D" backward-word # ⌥←
  bindkey "\e[1;3C" forward-word # ⌥→
fi
