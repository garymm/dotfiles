#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o xtrace

# Passwordless sudo
echo "${USER} ALL=(ALL) NOPASSWD: ALL" | sudo tee "/private/etc/sudoers.d/${USER}"

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
  difftastic \
  direnv \
  eza \
  fd \
  font-monaspace \
  fzf \
  gh \
  gnu-sed \
  icdiff \
  jq \
  koekeishiya/formulae/skhd \
  koekeishiya/formulae/yabai \
  source-highlight \
  starship \
  zoxide

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

rm -f ~/bin/cursor ~/bin/code
cp -r bin ~/
ln -s code ~/bin/cursor

# Install dotfiles from this repo
cp .zshrc ~/

# Install pixi
curl -fsSL https://pixi.sh/install.sh | bash

# mamba
# must come after copy .zshrc
curl --output /tmp/miniforge3.sh -L "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh"
bash /tmp/miniforge3.sh -u -b -p ~/miniforge3
zsh -c '~/miniforge3/bin/mamba init zsh'

cp -r .oh-my-zsh ~/
rm -rf ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd
git clone --depth 1 https://github.com/changyuheng/zsh-interactive-cd.git ~/.oh-my-zsh/custom/plugins/zsh-interactive-cd

cp .gitconfig ~/
cp -r mac/.config ~/
cp -r .config/* ~/.config/
cp -r mac/Library ~/

curl --output ~/bin/git-pair --location https://raw.githubusercontent.com/cac04/git-pair/master/git-pair
chmod +x ~/bin/git-pair

# https://github.com/koekeishiya/yabai/wiki/Installing-yabai-(latest-release)#configure-scripting-addition
echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
