#!/usr/bin/env bash

# TODO: Add a flag to control whether or not email (msmtp)
# is set up. I only need that for home servers, not work machines.

set -o errexit
set -o pipefail
set -o xtrace

git config --global user.email "garymm@garymm.org"
git config --global user.name "Gary Miguel"

sudo adduser "${USER}" sudo

# Install apt-fast
sudo add-apt-repository ppa:apt-fast/stable
sudo apt-get update
sudo apt-get install apt-fast

# sysstat contains sar for tmux-plugins/tmux-cpu
# pass is for msmtp oath2tool.sh
apt-fast install \
	direnv \
	icdiff \
	libsource-highlight-common \
	msmtp-mta \
	pass \
	ripgrep \
	source-highlight \
	sysstat \
	tmux \
	zsh

# This doesn't seem to work on GCP or Azure VM's.
chsh -s $(which zsh)

if [[ ! -d ~/.fzf ]]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	# oh-my-zsh plugin takes care of all of the `--no` things.
	~/.fzf/install --no-key-bindings --no-completion --no-update-rc
fi

if [[ ! -d ~/.tmux/plugins/tpm ]]; then
	mkdir -p ~/.tmux/plugins
	git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install oh-my-zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install dotfiles from this repo
cp .zshrc ~/
cp -r .oh-my-zsh ~/

cp .tmux.conf ~/
~/.tmux/plugins/tpm/bin/install_plugins

mkdir -p ~/bin
cp editor.sh ~/bin/

cp .direnvrc ~/

cp oauth2tool.sh ~/bin/
cp oauth2.py ~/bin/
sudo cp msmtprc /usr/local/etc/msmtprc
sudo ln -s /usr/local/etc/msmtprc /etc/msmtprc
touch /var/log/msmtp
chmod ugo+w /var/log/msmtp

cp .gitconfig ~/.gitconfig
