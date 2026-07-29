#!/bin/bash
#
# Idempotent VS Code install for Fedora. Safe to re-run: the key import, repo
# file, and package install each happen only when they are actually missing.
#
set -euo pipefail

REPO_FILE=/etc/yum.repos.d/vscode.repo
MS_KEY_URL=https://packages.microsoft.com/keys/microsoft.asc

# Already installed? Nothing to do.
if rpm -q code &>/dev/null || command -v code &>/dev/null; then
    echo "VS Code already installed: $(command -v code 2>/dev/null || rpm -q code)"
    exit 0
fi

# Import Microsoft GPG key (rpm --import is a no-op if already imported).
sudo rpm --import "$MS_KEY_URL"

# Add the VS Code repository only if the repo file isn't already present.
if [[ -f "$REPO_FILE" ]]; then
    echo "Repo already configured: $REPO_FILE"
else
    echo "Creating $REPO_FILE"
    sudo tee "$REPO_FILE" >/dev/null <<EOF
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=$MS_KEY_URL
EOF
fi

# Refresh package metadata (check-update exits 100 when updates exist).
sudo dnf check-update || true

# Install VS Code.
sudo dnf install code
