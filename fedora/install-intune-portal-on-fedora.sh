#!/bin/bash
#
# Idempotent Microsoft Edge (stable) install for Fedora. Safe to re-run: the key
# import, repo setup, and package install each happen only when they're missing.
#
set -euo pipefail

MS_KEY_URL=https://packages.microsoft.com/keys/microsoft.asc
INTUNE_REPO_URL=https://packages.microsoft.com/rhel/10/prod/config.repo

# Already installed? Nothing to do.
if rpm -q intune-portal &>/dev/null; then
    echo "Microsoft Intune Portal already installed: $(rpm -q intune-portal)"
    exit 0
fi

# Import Microsoft's signing key (rpm --import is a no-op if already imported).
sudo rpm --import "$MS_KEY_URL"

# Add the Edge repository only if it isn't already configured.
if compgen -G "/etc/yum.repos.d/*intune*.repo" >/dev/null; then
    echo "Intune repo already configured: $(ls /etc/yum.repos.d/*intune*.repo)"
else
    echo "Adding Intune repository"
    sudo curl -o /etc/yum.repos.d/microsoft-intune.repo $INTUNE_REPO_URL
fi

# Refresh metadata.
sudo dnf update --refresh

# Install Intune Portal.
sudo dnf install intune-portal
