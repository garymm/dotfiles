#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace


cd -- "$( dirname -- "${BASH_SOURCE[0]}" )"

email=""
docker=""

function usage {
	echo "Usage: $0 [--email] [--docker]"
}

while [ "$1" != "" ]; do
    case $1 in
        --email )   shift
					email="1"
					;;
		--docker )  shift
					docker="1"
					;;
		* )         usage
					exit 1
    esac
    shift
done

can_sudo=""

if sudo -l &>/dev/null; then
    can_sudo="1"
fi

USER=$(whoami)

if [ -n "${can_sudo}" ]; then
	sudo adduser "${USER}" sudo
    echo "${USER} ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers
	# Install apt-fast repo
	sudo add-apt-repository -y ppa:apt-fast/stable
	sudo apt-get update
fi


# sysstat contains sar for tmux-plugins/tmux-cpu
apt-fast install -y \
	autojump \
	fd-find \
	gh \
	icdiff \
	libsource-highlight-common \
	ripgrep \
	source-highlight \
	sysstat \
	tmux \
	zoxide \
	zsh

# For users that use non-regular login (e.g. LDAP), chsh won't work.
if [[ -n $(grep "^${USER}:" /etc/passwd) ]]; then
	current_shell=$(getent passwd "${USER}" | cut -d: -f7)
	desired_shell="$(which zsh)"
	if [ "${current_shell}" != "${desired_shell}" ]; then
		chsh -s "${desired_shell}"
	fi
fi

rm -rf ~/.tmux/plugins
mkdir -p ~/.tmux/plugins
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
cp .tmux.conf ~/
~/.tmux/plugins/tpm/bin/install_plugins

# Install oh-my-zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
	env RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install dotfiles from this repo
cp .zshrc ~/
cp -r .oh-my-zsh ~/
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd
git clone --depth 1 https://github.com/changyuheng/zsh-interactive-cd.git  ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd


mkdir -p ~/.config/
cp -r .config/* ~/.config/

rm -f ~/bin/cursor ~/bin/code
cp -r bin ~/
ln -s code ~/bin/cursor
curl -sfL https://direnv.net/install.sh | bin_path=~/bin bash
curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair

# TODO: Remove if https://github.com/bottlerocketlabs/remote-pbcopy/pull/5
if [[ $(uname -m) == "x86_64" ]]; then
	curl --output /tmp/rpbcopy.tar.gz --location "https://github.com/bottlerocketlabs/remote-pbcopy/releases/download/v0.1.5/rpbcopy_0.1.5_Linux_$(dpkg --print-architecture).tar.gz"
	tar -xvf /tmp/rpbcopy.tar.gz -C /tmp
	mv /tmp/rpbcopy ~/bin/pbcopy
fi

cp .gitconfig ~/

if [[ -n "${email}" ]]; then
	./setup-ubuntu-email.sh
fi

if [[ -n "${docker}" ]]; then
	./setup-ubuntu-docker.sh
fi
