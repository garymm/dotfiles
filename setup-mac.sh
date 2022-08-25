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
    jq \
    koekeishiya/formulae/skhd \
    koekeishiya/formulae/yabai \
	  source-highlight

# Install casks
${BREW} install --cask \
    anaconda \
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
cp -r .oh-my-zsh ~/

cp .gitconfig ~/

cp -r mac/.config ~/
cp -r mac/Library ~/

curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair
