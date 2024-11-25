#!/bin/bash

# Only version for xubuntu for now

# Assumptions
# git is installed
# bash is the shell

set -x

# Basic setup
curdir=$(pwd)
sudo chmod 777 -R /opt
deps="cargo ripgrep"
sudo apt install -y $deps
if ! rg cargo/bin ~/.bashrc &>/dev/null
then
  echo 'export PATH="$PATH:HOME/.cargo/bin"' >> ~/.bashrc
fi

# Install helix
if ! command -v hx &>/dev/null
then
  cd /opt
  git clone https://github.com/helix-editor/helix
  cd helix
  git remote add keymap_labels https://github.com/MattCheely/helix
  git checkout -b keymap_labels
  git pull --rebase keymap_labels labels-for-config-menus
  cargo install --path helix-term --locked
  cd -
fi

# Language servers
## bash
if ! command -v bash-language-server &>/dev/null
then
  sudo snap install bash-language-server --classic
fi
