#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

sudo adduser "${USER}" sudo

# Passwordless sudo
echo "${USER} ALL=(ALL) ALL" | sudo tee -a /etc/sudoers.d/sudoers

# Install apt-fast repo
sudo add-apt-repository -y ppa:apt-fast/stable
sudo apt-get update

# Install gh repo, based on https://github.com/cli/cli/tree/trunk/docs
type -p curl >/dev/null || (sudo apt update && sudo apt install curl -y)
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# install apt-fast
sudo apt-get install -y apt-fast

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
if [[ -n $(grep ${USER} /etc/passwd) ]]; then
	chsh -s $(which zsh)
fi

if [[ ! -d ~/.fzf ]]; then
	git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
	# oh-my-zsh plugin takes care of all of the `--no` things.
	~/.fzf/install --no-key-bindings --no-completion --no-update-rc
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

# mamba
# Comes after .zshrc is installed so that it modifies it.
curl --output /tmp/mambaforge.sh --location "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash /tmp/mambaforge.sh -u -b -p ~/mambaforge
zsh -c '~/mambaforge/bin/mamba init zsh'

cp -r .config/* ~/.config/

cp -r bin ~/
rm -f ~/bin/cursor
ln -s ~/bin/cursor code
curl -sfL https://direnv.net/install.sh | bin_path=~/bin bash
ln -s $(which fdfind) ~/bin/fd
curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair

wget "https://github.com/bottlerocketlabs/remote-pbcopy/releases/download/v0.1.5/rpbcopy_0.1.5_Linux_$(dpkg --print-architecture).tar.gz" -O /tmp/rpbcopy.tar.gz
tar -xvf /tmp/rpbcopy.tar.gz -C /tmp
mv /tmp/rpbcopy ~/bin/pbcopy

cp .gitconfig ~/

if [[ -n "${email}" ]]; then
	./setup-ubuntu-email.sh
fi

if [[ -n "${docker}" ]]; then
	./setup-ubuntu-docker.sh
fi
