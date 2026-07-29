#!/bin/bash
#
# Idempotent Microsoft Edge (stable) install for Fedora. Safe to re-run: the key
# import, repo setup, and package install each happen only when they're missing.
#
set -euo pipefail

MS_KEY_URL=https://packages.microsoft.com/keys/microsoft.asc
EDGE_REPO_URL=https://packages.microsoft.com/yumrepos/edge/config.repo

# Already installed? Nothing to do.
if rpm -q microsoft-edge-stable &>/dev/null; then
    echo "Microsoft Edge already installed: $(rpm -q microsoft-edge-stable)"
    exit 0
fi

# Import Microsoft's signing key (rpm --import is a no-op if already imported).
sudo rpm --import "$MS_KEY_URL"

# Add the Edge repository only if it isn't already configured.
if compgen -G "/etc/yum.repos.d/*edge*.repo" >/dev/null; then
    echo "Edge repo already configured: $(ls /etc/yum.repos.d/*edge*.repo)"
else
    echo "Adding Edge repository"
    sudo dnf config-manager addrepo --from-repofile="$EDGE_REPO_URL"
fi

# Refresh metadata.
sudo dnf update --refresh

# Install Edge.
sudo dnf install microsoft-edge-stable
