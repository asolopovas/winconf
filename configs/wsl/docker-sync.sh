#!/bin/bash
# Update the apt package list.
sudo apt-get update -y
sudo apt-get upgrade -y

sudo apt-get install git neovim ruby ruby-dev ruby-bundler -y
sudo gem install docker-sync
# echo "export DOCKER_HOST=tcp://127.0.0.1:2375" >> ~/.bashrc
# echo "export DOCKER_HOST=tcp://127.0.0.1:2375" >> ~/.zshrc
sudo apt-get install build-essential -y
mkdir ~/tmp
pushd ~/tmp
# Compile and install OCaml
sudo apt-get install make -y
wget http://caml.inria.fr/pub/distrib/ocaml-4.08/ocaml-4.08.1.tar.gz
tar xvf ocaml-4.08.1.tar.gz
cd ocaml-4.08.1
./configure
make -j$(nproc) world
make -j$(nproc) opt
umask 022
sudo make install
sudo make clean
# # Compile and install Unison
pushd ~/tmp
wget https://github.com/bcpierce00/unison/archive/v2.51.2.tar.gz
tar xvf v2.51.2.tar.gz
cd unison-2.51.2
# The implementation src/system.ml does not match the interface system.cmi:curl and needs to be patched
curl https://github.com/bcpierce00/unison/commit/23fa1292.diff?full_index=1 -o patch.diff
git apply patch.diff
make UISTYLE=text
sudo cp src/unison /usr/local/bin/unison
sudo cp src/unison-fsmonitor /usr/local/bin/unison-fsmonitor
# sudo ln -s "/mnt/c/Program Files/Docker/Docker/resources/bin/docker-compose.exe" /usr/local/bin/docker-compose
# sudo ln -s "/mnt/c/Program Files/Docker/Docker/resources/bin/docker.exe" /usr/local/bin/docker
