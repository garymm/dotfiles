#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

sudo adduser "${USER}" sudo

# Install apt-fast
sudo add-apt-repository ppa:apt-fast/stable
sudo apt-get update
sudo apt-get install apt-fast

email=""

function usage {
	echo "Usage: $0 [--setup-email]"
}

while [ "$1" != "" ]; do
    case $1 in
        --setup-email )     shift
							email="1"
							;;
		* )                 usage
							exit 1
    esac
    shift
done

# sysstat contains sar for tmux-plugins/tmux-cpu
apt-fast install \
	direnv \
	icdiff \
	libsource-highlight-common \
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
curl -o ~/.oh-my-zsh/plugins https://raw.githubusercontent.com/bazelbuild/bazel/master/scripts/zsh_completion/_bazel

cp .tmux.conf ~/
~/.tmux/plugins/tpm/bin/install_plugins

cp -r bin ~/
curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair

cp .gitconfig ~/

if [[ -n "${email}" ]]; then
	# pass is for oath2tool.sh
	apt-fast install msmtp-mta pass
	cp oauth2tool.sh ~/bin/
	cp oauth2.py ~/bin/
	sudo cp msmtprc /usr/local/etc/msmtprc
	sudo ln -s /usr/local/etc/msmtprc /etc/msmtprc
	touch /var/log/msmtp
	chmod ugo+w /var/log/msmtp
fi

