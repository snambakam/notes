#!/bin/bash
#
# Idempotent OpenVPN 3 install for Fedora. Safe to re-run: the repo file and the
# package install each happen only when they're actually missing.
#
# Common commands:
#   openvpn3 session-start  --config <your.ovpn>
#   openvpn3 sessions-list
#   openvpn3 session-manage --config myvpn --disconnect
#
set -euo pipefail

REPO_URL="https://packages.openvpn.net/openvpn3/repos/openvpn3-fedora.repo"
REPO_FILE="/etc/yum.repos.d/openvpn3-fedora.repo"
PKG="openvpn3"

# This script targets Fedora / dnf.
if ! command -v dnf &>/dev/null; then
    echo "ERROR: dnf not found; this script targets Fedora." >&2
    exit 1
fi

# Already installed? Nothing to do.
if rpm -q "$PKG" &>/dev/null; then
    echo "$PKG already installed: $(rpm -q "$PKG")"
    exit 0
fi

# Add the OpenVPN 3 repository only if it isn't already present.
if [[ -f "$REPO_FILE" ]]; then
    echo "Repo already configured: $REPO_FILE"
elif command -v curl &>/dev/null; then
    echo "Adding OpenVPN 3 repository -> $REPO_FILE"
    sudo curl -fsSL "$REPO_URL" -o "$REPO_FILE"
else
    echo "ERROR: curl not found; install it (sudo dnf install curl) or add $REPO_URL manually." >&2
    exit 1
fi

# Refresh metadata for the new repo (imports the repo GPG key on first use).
sudo dnf makecache

# Install OpenVPN 3.
sudo dnf install -y "$PKG"

echo
echo "Installed $(rpm -q "$PKG")."
echo "Usage:"
echo "  Start      : openvpn3 session-start  --config <your.ovpn>"
echo "  List       : openvpn3 sessions-list"
echo "  Disconnect : openvpn3 session-manage --config myvpn --disconnect"
