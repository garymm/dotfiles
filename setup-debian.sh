#!/usr/bin/env bash

set -o errexit
set -o pipefail

git config --global user.email "garymm@gmail.com"
git config --global user.name "Gary Miguel"

sudo adduser "${USER}" sudo

# Install apt-fast
sudo add-apt-repository ppa:apt-fast/stable
sudo apt-get update
sudo apt-get install apt-fast

# For sar for tmux-plugins/tmux-cpu
apt-fast install \
	direnv \
	libsource-highlight-common \
	ripgrep \
	source-highlight \
	sysstat \
	tmux \
	zsh

chsh -s $(which zsh)

if [[ ! -d ~/.fzf ]]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	~/.fzf/install
fi

if [[ ! -d ~/.tmux/plugins/tpm ]]; then
	mkdir -p ~/.tmux/plugins
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

~/.tmux/plugins/tpm/bindings/install_plugins

# From https://medium.com/@oliverspryn/adding-git-completion-to-zsh-60f3b0e7ffbc
mkdir -p ~/.zsh
curl -o ~/.zsh/git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o ~/.zsh/_git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh

# Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Install dotfiles from this repo
cp .zshrc ~/
cp -r .oh-my-zsh ~/
cp .tmux.conf ~/
mkdir -p ~/bin
cp editor.sh ~/bin/
