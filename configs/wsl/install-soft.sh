#!/bin/bash

sudo apt update
sudo apt upgrade -y
sudo apt remove vim -y
sudo apt install curl zsh neovim build-essential -y

# Oh My zsh
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sudo cp -r ~/.oh-my-zsh /usr/share/oh-my-zsh
rm -rf .oh-my-zsh
sudo chsh -s $(which zsh) andrius

curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

pushd ~
git init
git remote add origin git@github.com:asolopovas/dotfiles.git
git fetch origin
git reset origin/master
git branch --set-upstream-to origin/master
