#!/bin/bash

sudo dnf install -y \
	autoconf \
	automake \
	clang \
	cmake \
	curl \
	gcc \
	g++ \
	gdb \
	git \
	golang \
	libtool \
	wget

#
# Install Rust
#

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
