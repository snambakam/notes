#!/bin/bash
#
# Idempotent Git Credential Manager (GCM) install for Fedora. GCM does not
# ship an RPM, so we install the self-contained linux-x64 tarball release
# from GitHub. Safe to re-run: download/extract/configure are skipped when
# the requested version is already installed.
#
set -euo pipefail

INSTALL_DIR=/usr/local/bin
GCM_BIN="$INSTALL_DIR/git-credential-manager"
REPO=git-ecosystem/git-credential-manager

# Resolve the latest release tag (e.g. v2.9.1) via the GitHub API. The
# response is captured first so grep -m1 can't close the pipe on curl early
# (which would otherwise trip "curl: (23) Failure writing output").
RELEASE_JSON=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest")
TAG=$(grep -m1 '"tag_name"' <<<"$RELEASE_JSON" | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
VERSION=${TAG#v}

# Already installed at this version? Nothing to do.
if command -v git-credential-manager &>/dev/null && git-credential-manager --version 2>/dev/null | grep -q "$VERSION"; then
    echo "git-credential-manager $VERSION already installed: $(command -v git-credential-manager)"
    exit 0
fi

ASSET="gcm-linux-x64-$VERSION.tar.gz"
URL="https://github.com/$REPO/releases/download/$TAG/$ASSET"

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

echo "Downloading $URL"
curl -fsSL "$URL" -o "$WORKDIR/$ASSET"

echo "Extracting to $INSTALL_DIR"
sudo tar -xzf "$WORKDIR/$ASSET" -C "$INSTALL_DIR"

echo "Configuring git to use GCM as its credential helper"
"$GCM_BIN" configure

echo "Installed: $("$GCM_BIN" --version)"
