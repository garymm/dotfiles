#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

echo "${USER} ALL=(ALL) ALL" >> /tmp/sudoers
sudo chown root /tmp/sudoers
sudo mv /tmp/sudoers /etc/sudoers.d/

if [[ $(uname -m) == "arm64" ]]; then
  BREW_PREFIX=/opt/homebrew
else
  BREW_PREFIX=/usr/local
fi

BREW="${BREW_PREFIX}/bin/brew"

# Install homebrew
if [[ ! -e "${BREW}" ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

${BREW} tap homebrew/cask-fonts

# Install formulae
${BREW} install \
    fzf \
    gnu-sed \
    icdiff \
    jq \
    koekeishiya/formulae/skhd \
    koekeishiya/formulae/yabai \
	  source-highlight

# Install casks
${BREW} install --cask \
    font-fira-code \
    kitty \
    stats \
    visual-studio-code

"${BREW_PREFIX}/bin/code" --install-extension kshetline.ligatures-limited

# oh-my-zsh plugin takes care of all of the `--no` things.
${BREW_PREFIX}/opt/fzf/install --no-key-bindings --no-completion --no-update-rc

# Install oh-my-zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
	sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

cp -r bin ~/

# Install dotfiles from this repo
cp .zshrc ~/

# mamba / conda.
# Comes after .zshrc is installed so that it modifies it.
curl --output /tmp/mambaforge.sh --location "https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-$(uname)-$(uname -m).sh"
bash /tmp/mambaforge.sh -b -p ~/mambaforge
ln -s ~/mambaforge/bin/mamba ~/bin/conda
zsh -c '~/mambaforge/bin/mamba init zsh'

cp -r .oh-my-zsh ~/
git clone https://github.com/changyuheng/zsh-interactive-cd.git  ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd

cp .gitconfig ~/

cp -r mac/.config ~/
cp -r .config/* ~/.config/
cp -r mac/Library ~/

curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair

# Passwordless sudo
# echo "${USER} ALL=(ALL) NOPASSWD: ALL" > "/tmp/${USER}"
# sudo mv "/tmp/${USER}" /private/etc/sudoers.d/
# sudo chown root /private/etc/sudoers.d/${USER}
