#!/usr/bin/env bash
set -e

echo "==> Installing base dependencies..."
sudo apt update && sudo apt install -y git stow

echo "==> Symlinking dotfiles..."
cd "$HOME/dotfiles"
stow --dotfiles git
stow --dotfiles bash
stow vscodium

echo "==> Configuring global Git settings..."
git config --global core.excludesfile "$HOME/.gitignore"

