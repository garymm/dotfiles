#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

email=""
docker=""

function usage {
	echo "Usage: $0 [--email] [--docker]"
}

while [ "$1" != "" ]; do
	case $1 in
	--email)
		shift
		email="1"
		;;
	--docker)
		shift
		docker="1"
		;;
	*)
		usage
		exit 1
		;;
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
	sudo apt-get install -y apt-fast
fi

# Install pixi
curl -fsSL https://pixi.sh/install.sh | bash

PATH="${HOME}/.pixi/bin:${PATH}"

pixi global install \
	fd-find \
	fzf \
	gh \
	git \
	ripgrep \
	starship \
	zoxide

function install_prefer_apt {
	if ! command -v "${1}" &>/dev/null; then
		if [ -n "${can_sudo}" ]; then
			sudo apt-fast install -y "${1}"
		else
			pixi global install "${1}"
		fi
	fi
}

set +o errexit
set +o pipefail
# the conda-forge versions of these don't behave quite right
# so only install them with pixi if we have to.
install_prefer_apt tmux
install_prefer_apt zsh
set -o errexit
set -o pipefail

if [[ $(uname -m) == "x86_64" ]]; then
	# sysstat contains sar for tmux-plugins/tmux-cpu
	pixi global install \
		eza \
		source-highlight \
		sysstat
fi

desired_shell="$(which zsh)"
# For users that use non-regular login (e.g. LDAP), chsh won't work.
if [[ -n $(grep "^${USER}:" /etc/passwd) ]]; then
	current_shell=$(getent passwd "${USER}" | cut -d: -f7)
	if [ "${current_shell}" != "${desired_shell}" ]; then
		chsh -s "${desired_shell}"
	fi
else
	echo "export SHELL=${desired_shell}" >"${HOME}/.bash_profile"
	echo "exec ${desired_shell} -l" >>"${HOME}/.bash_profile"
fi

rm -rf ~/.tmux/plugins
mkdir -p ~/.tmux/plugins
git clone --depth 1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
cp .tmux.conf ~/
# Not sure why but tmux from pixi doesn't like xterm-kitty
TERM=xterm ~/.tmux/plugins/tpm/bin/install_plugins

# Install oh-my-zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
	env ZSH= RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Install dotfiles from this repo
cp .zshrc ~/
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd
git clone --depth 1 https://github.com/changyuheng/zsh-interactive-cd.git ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd

# mamba
# must come after copy .zshrc
curl --output /tmp/miniforge3.sh -L "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash /tmp/miniforge3.sh -u -b -p ~/miniforge3
zsh -c '~/miniforge3/bin/mamba init zsh'

mkdir -p ~/.config/
cp -r .config/* ~/.config/

if [[ ! -f ~/.ssh/config ]]; then
  mkdir -p ~/.ssh
  cp .ssh/config ~/.ssh/config
fi

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

readonly DIFFT_ARCHIVE=/tmp/difftastic.tar.gz
curl --output "${DIFFT_ARCHIVE}" -L https://github.com/Wilfred/difftastic/releases/download/0.57.0/difft-$(uname -m)-unknown-linux-gnu.tar.gz
tar xfz "${DIFFT_ARCHIVE}"
chmod +x ./difft
mv ./difft ~/bin/

cp .gitconfig ~/

if [[ -n "${email}" ]]; then
	./setup-ubuntu-email.sh
fi

if [[ -n "${docker}" ]]; then
	./setup-ubuntu-docker.sh
fi
