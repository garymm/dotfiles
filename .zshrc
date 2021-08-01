# Path to your oh-my-zsh installation.
export ZSH=${HOME}/.oh-my-zsh

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="garymm"

# Set list of themes to load
# Setting this variable when ZSH_THEME=random
# cause zsh load theme from this variable instead of
# looking in ~/.oh-my-zsh/themes/
# An empty array have no effect
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

export FZF_BASE="${HOME}/.fzf"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  colored-man-pages
  direnv
  docker
  fzf
  tmux
  zsh-interactive-cd
)


source $ZSH/oh-my-zsh.sh

# User configuration

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    export PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    export PATH="$HOME/.local/bin:$PATH"
fi


# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

if [[ "${TERM_PROGRAM}" -eq "vscode" ]]; then
  export EDITOR="${HOME}/bin/editor.sh"
else
  export EDITOR="vim"
fi

alias ls='ls -FG' # G is color, F is trailing slashes, etc.
alias sed='sed --regexp-extended'
alias curl='curl --location' # follow redirects
export LESSOPEN='| /usr/share/source-highlight/src-hilite-lesspipe.sh %s'
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
  IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
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
else
  function refresh_env { }
fi

# Ensures PATH can find vscode
alias code='refresh_env && \code'

mkdir -p /tmp/ssh-master

# Load Git completion
# From https://medium.com/@oliverspryn/adding-git-completion-to-zsh-60f3b0e7ffbc
# Not using gitfast plugin because of
# https://github.com/ohmyzsh/ohmyzsh/issues/8894
zstyle ':completion:*:*:git:*' script ~/.zsh/git-completion.bash
fpath=(~/.zsh $fpath)
autoload -Uz compinit && compinit

