#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install build-essential tcl -y
mkdir -p ~/tmp
cd ~/tmp
curl -O http://download.redis.io/redis-stable.tar.gz
tar xzvf redis-stable.tar.gz
rm -f redis-stable.tar.gz
cd ~/tmp/redis-stable/deps
make hiredis jemalloc linenoise lua geohash-int
cd ~/tmp/redis-stable
make & make test
sudo make install

sudo adduser --system --group --no-create-home redis
