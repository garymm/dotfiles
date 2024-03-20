#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

# Passwordless sudo
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
    autojump \
    bash \
    direnv \
    fd \
    font-monaspace \
    fzf \
    gh \
    gnu-sed \
    icdiff \
    jq \
    koekeishiya/formulae/skhd \
    koekeishiya/formulae/yabai \
	  source-highlight

# Install casks
${BREW} install --cask \
    cursor \
    homebrew/cask-versions/dash6 \
    font-fira-code \
    kitty \
    raycast \
    stats \
    visual-studio-code

cursor_extensions=(
  "deerawan.vscode-dash"
  "eamodio.gitlens"
  "GitHub.vscode-pull-request-github"
  "kahole.magit"
  "ms-vscode-remote.remote-ssh-edit"
  "ms-vscode-remote.remote-ssh"
  "ms-vscode.remote-explorer"
)

for extension in "${cursor_extensions[@]}"; do
  "${BREW_PREFIX}/bin/cursor" --install-extension "${extension}"
done


code_extensions=(
  "${cursor_extensions[@]}"
  "GitHub.copilot-chat"
  "GitHub.copilot"
)

for extension in "${code_extensions[@]}"; do
  "${BREW_PREFIX}/bin/code" --install-extension "${extension}"
done

# oh-my-zsh plugin takes care of all of the `--no` things.
${BREW_PREFIX}/opt/fzf/install --no-key-bindings --no-completion --no-update-rc

# Install oh-my-zsh
if [[ ! -d ~/.oh-my-zsh ]]; then
  env RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

cp -r bin ~/
rm -f ~/bin/cursor
ln -s code ~/bin/cursor

# Install dotfiles from this repo
cp .zshrc ~/

# micromamba
# Comes after .zshrc is installed so that it modifies it.
"${SHELL}" <(curl -L micro.mamba.pm/install.sh)
zsh -c '~/.local/bin/micromamba init zsh'

cp -r .oh-my-zsh ~/
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd
git clone --depth 1 https://github.com/changyuheng/zsh-interactive-cd.git  ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd

cp .gitconfig ~/
cp -r mac/.config ~/
cp -r .config/* ~/.config/
cp -r mac/Library ~/

curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair

