#!/bin/sh

ERLANG_VERSION=25.0.2-1
ELIXIR_VERSION=1.14.5
NODE_VERSION=16

# Install basic packages
apt-get -qq update
apt-get install -y \
wget \
git \
unzip \
build-essential \
curl \ 
ffmpeg \
chromium-browser

# Install Erlang
echo "deb http://packages.erlang-solutions.com/ubuntu bionic contrib" >> /etc/apt/sources.list && \
apt-key adv --fetch-keys http://packages.erlang-solutions.com/ubuntu/erlang_solutions.asc && \
apt-get -qq update && \
apt-get install -y -f \
esl-erlang="1:${ERLANG_VERSION}"

# Install Elixir
cd / && \
git clone https://github.com/elixir-lang/elixir.git && \
cd elixir && \
git checkout v$ELIXIR_VERSION && \
make && \
make install

'/usr/local/bin/mix local.hex --force && /usr/local/bin/mix local.rebar --force'

# Install nodejs and npm
curl -sL https://deb.nodesource.com/setup_$NODE_VERSION.x | sudo -E bash -
apt-get install -y nodejs

# Firewall
ufw allow 80
ufw allow 443