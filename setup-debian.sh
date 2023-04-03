#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

sudo adduser "${USER}" sudo

# Install apt-fast
sudo add-apt-repository -y ppa:apt-fast/stable
sudo apt-get update
sudo apt-get install -y apt-fast

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
apt-fast install -y \
	autojump \
	icdiff \
	libsource-highlight-common \
	ripgrep \
	source-highlight \
	sysstat \
	tmux \
	zsh

curl -sfL https://direnv.net/install.sh | bash

# This doesn't seem to work on GCP or Azure VM's.
chsh -s $(which zsh)

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

# mamba / conda.
# Comes after .zshrc is installed so that it modifies it.
curl --output /tmp/mambaforge.sh --location "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash /tmp/mambaforge.sh -u -b -p ~/mambaforge
zsh -c '~/mambaforge/bin/mamba init zsh'

cp -r .config ~/

cp -r bin ~/
curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair

cp .gitconfig ~/

# Passwordless sudo
# echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/tmp/${USER}"
# sudo mv "/tmp/${USER}" /etc/sudoers.d/
# sudo chown root /etc/sudoers.d/${USER}

if [[ -n "${email}" ]]; then
	# pass is for oath2tool.sh
	apt-fast install msmtp-mta pass
	cp oauth2tool.sh ~/bin/
	cp oauth2.py ~/bin/
	sudo cp msmtprc /usr/local/etc/msmtprc
	sudo ln -s /usr/local/etc/msmtprc /etc/msmtprc
	touch /var/log/msmtp
	chmod ugo+w /var/log/msmtp
	sudo cp .offlineimaprc /root/
	cp offlineimap.py ~/bin/
fi
