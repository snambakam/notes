#!/bin/bash

sudo dnf install -y \
	autoconf \
	automake \
	bc \
	bison \
	clang \
	cmake \
	curl \
	elfutils-libelf-devel \
	flex \
	gcc \
	g++ \
	gdb \
	git \
	golang \
	libtool \
	perl \
	make \
	mock \
	ncurses-devel \
	openssl \
	openssl-devel \
	wget


#
# Install Rust
#

curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
