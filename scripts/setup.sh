#!/bin/bash

# Only version for xubuntu for now

# Assumptions
# git is installed
# bash is the shell

sys=xubuntu
source config_$sys

log() {
  { x_opt=$(shopt -op xtrace); set +x; } 2>/dev/null
  echo -e "\e[32m$1\e[0m"
  eval "$x_opt"
}

not_installed() {
  log "Checking if $1 is installed"
  return ! command -v $1 &>/dev/null
}

configure_cargo() {
	if ! rg cargo/bin ~/.bashrc &>/dev/null
	then
		echo 'export PATH="$PATH:HOME/.cargo/bin"' >> ~/.bashrc
	fi
}

configure() {
	for target in $@
	do
		if command -v configure_$target
		then
			configure_$target
		fi
	done
}

set -xe

# Basic setup
curdir=$(pwd)
sudo chmod 777 -R /opt

log "Installing tools"
install $tools
log "Configuring tools"
configure $tools

# clone dotfiles
log "Checking if dotfiles repository is cloned"
if ! test -d $dotfiles_path
then
  log "Cloning dotfiles repository"
  dotfiles_dir=$(basename $dotfiles_path)
  mkdir -p $dotfiles_dir
  cd $dotfiles_dir
  git clone https://github.com/tp86/dotfiles
fi

# Install tmux
if not_installed tmux
then
  install tmux
fi
log "Checking need for configuring tmux"
if ! test -L $HOME/.tmux.conf
then
  log "Configuring tmux"
  ln -sf $dotfiles_path/.tmux.conf $HOME/.tmux.conf
fi

# TODO
# kanata, batcat, lazygit, lf, delta, themes (tools + xfce4-terminal), fzf
# lf ideas: https://github.com/gokcehan/lf/wiki/Integrations#fzf
# bash configuration + aliases

# Install helix
if not_installed hx
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
  ln -sf $dotfiles_path/.config/helix $HOME/.config/helix
fi

# Install zathura
if not_installed zathura
then
  log "Installing zathura"
  install zathura
fi
if ! test -L $HOME/.config/zathura
then
  log "Configuring zathura"
  ln -sf $dotfiles_path/.config/zathura $HOME/.config/zathura
fi

# Language servers
## bash
if not_installed bash-language-server
then
  log "Installing language server for bash"
  sudo snap install bash-language-server --classic
fi

cd $curdir
