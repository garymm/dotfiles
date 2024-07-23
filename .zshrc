# Path to your oh-my-zsh installation.
export ZSH=${HOME}/.oh-my-zsh

COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  bazel
  colored-man-pages
  direnv
  docker
  fzf
  gitfast
  kubectl
  starship
  zoxide
  zsh-interactive-cd
)

# ssh-agent plugin interferes with VSCode's remote SSH stuff.
# ssh-agent plugin interferes with VSCode's remote SSH stuff.
if ! [[ "$(uname)" == "Linux" && "${VSCODE_INJECTION}" == "1" && -n "${SSH_CONNECTION}" ]]; then
  if [ -d "${HOME}/.ssh" ]; then
    plugins+=(ssh-agent)
  fi
fi

if command -v rustup &> /dev/null; then
  plugins+=(rust)
fi

zstyle :omz:plugins:ssh-agent agent-forwarding yes

# https://github.com/junegunn/fzf/issues/164#issuecomment-581837757
bindkey "ç" fzf-cd-widget

# Seems required for kitty, but probably doesn't hurt otherwise.
# https://apple.stackexchange.com/q/269324/34090
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# Add to PATH. do this before the plugins are loaded so that they find
# binaries in these directories.

# https://unix.stackexchange.com/a/62599/88047
typeset -U path PATH

if [ -d "$HOME/.local/bin" ] ; then
    path=("$HOME/.local/bin" "$path[@]")
fi

if [ -d /usr/local/go/bin ] ; then
    path=("/usr/local/go/bin" "$path[@]")
fi

if [ -d "$HOME/miniforge3/bin" ] ; then
    path=("$HOME/miniforge3/bin" "$path[@]")
fi

if [ -d "${HOME}/.pixi" ]; then
  path=("${HOME}/.pixi/bin" "$path[@]")
  autoload -Uz compinit
  compinit
  eval "$(pixi completion --shell zsh)"
fi

if [[ $(uname) == "Darwin" ]]; then
  if [[ $(uname -m) == "arm64" ]]; then
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
  export FZF_BASE="${HOME}/.pixi/envs/fzf/share/fzf"
  LESSPIPE="/usr/share/source-highlight/src-hilite-lesspipe.sh"
  plugins+=(tmux)
fi

if [ -d "$HOME/bin" ] ; then
    path=("$HOME/bin" "$path[@]")
fi

# Zsh from mambaforge doesn't set ZSH_VERSION for some reason
if [ -z "${ZSH_VERSION}" ]; then
  ZSH_VERSION="5.9"
fi

source $ZSH/oh-my-zsh.sh

export EDITOR="${HOME}/bin/editor.sh"

alias ls='ls -FG' # G is color, F is trailing slashes, etc.
alias sed='sed -r'
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
  local BASE_BRANCH
  if git rev-parse --verify main >/dev/null 2>&1; then
      BASE_BRANCH="main"
  else
      BASE_BRANCH="master"
  fi
  git switch --create "$@" "${BASE_BRANCH}"
}

function echoerr() {
  echo "$@" 1>&2
}

mkdir -p /tmp/ssh-master

# https://sw.kovidgoyal.net/kitty/kittens/ssh/
SSH_BIN=$(which -a ssh | grep '^/' | head -1)

function ssh {
  declare -a command=( "$@" )

  if [[ "${TERM}" == "xterm-kitty" ]] && command -v kitty &> /dev/null && [[ -z "${SSH_CONNECTION}" ]] ; then
    command[1,0]=( kitty +kitten ssh )
  else
    command[1,0]=( "${SSH_BIN}" )
  fi
  "$command[@]"
}

# https://github.com/kovidgoyal/kitty/issues/838#issuecomment-770328902
if [[ "${TERM}" == "xterm-kitty" ]]; then
  bindkey "\e[1;3D" backward-word # ⌥←
  bindkey "\e[1;3C" forward-word # ⌥→
fi

export HOMEBREW_NO_ENV_HINTS=1  # Disable annoying homebrew hints

if [ -n "${TMUX}" ]; then
  function refresh_env {
    IFS=$'\n' VARS=($(tmux show-environment | grep -v '^-'))
    for VAR in $VARS; do
      export $VAR
    done
  }
  # Ensures SSH_AUTH_SOCK is set appropriately
  for cmd in ssh scp git; do
    alias $cmd="refresh_env && \\$cmd"
  done
fi

export VIRTUAL_ENV_DISABLE_PROMPT=1 # Don't show virtualenv in prompt. Starship instead.
