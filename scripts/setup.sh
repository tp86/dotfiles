#!/bin/bash

# Only version for xubuntu for now

# Assumptions
# git is installed
# bash is the shell

log() {
  { x_opt=$(shopt -op xtrace); set +x; } 2>/dev/null
  echo -e "\e[32m$1\e[0m"
  eval "$x_opt"
}

set -x

# Basic setup
curdir=$(pwd)
sudo chmod 777 -R /opt
log "Installing tools"
tools=$(cat <<EOF
cargo
ripgrep
EOF
)

sudo apt install -y $tools
log "Configuring tools"
if ! rg cargo/bin ~/.bashrc &>/dev/null
then
  echo 'export PATH="$PATH:HOME/.cargo/bin"' >> ~/.bashrc
fi

# clone dotfiles
log "Checking if dotfiles repository is cloned"
if ! test -d $HOME/Projects/other/dotfiles
then
  log "Cloning dotfiles repository"
  mkdir -p $HOME/Projects/other
  cd $HOME/Projects/other
  git clone https://github.com/tp86/dotfiles
fi

# Install helix
log "Checking if helix is already installed in correct version"
if ! command -v hx &>/dev/null
then
  log "Installing helix"
  cd /opt
  git clone https://github.com/helix-editor/helix
  cd helix
  git remote add keymap_labels https://github.com/MattCheely/helix
  git checkout -b keymap_labels
  git pull --rebase keymap_labels labels-for-config-menus
  cargo install --path helix-term --locked
fi
log "Checking need for configuring helix"
if ! test -L $HOME/.config/helix
then
  log "Configuring helix"
  ln -sf $HOME/Projects/other/dotfiles/.config/helix $HOME/.config/helix
fi

# Language servers
## bash
log "Checking if language server for bash is installed"
if ! command -v bash-language-server &>/dev/null
then
  log "Installing language server for bash"
  sudo snap install bash-language-server --classic
fi
