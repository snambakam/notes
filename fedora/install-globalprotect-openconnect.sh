#!/bin/bash
#
# Idempotent install of globalprotect-openconnect (yuezk COPR) on Fedora: a GUI
# GlobalProtect VPN client with SAML/MFA support, built on OpenConnect. Safe to
# re-run: enabling the COPR and installing the package happen only when needed.
#
# NOTE: this OpenConnect-based client does NOT submit HIP (Host Information
# Profile) endpoint-posture data. If your GlobalProtect gateway enforces HIP
# checks, it may reject this client -- use the official Palo Alto Linux client
# in that case.
#
set -euo pipefail

COPR_REPO="yuezk/globalprotect-openconnect"
PKG="globalprotect-openconnect"

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

# Enable the COPR repo only if it isn't already enabled.
if dnf copr list 2>/dev/null | grep -qiF "$COPR_REPO" \
   || compgen -G "/etc/yum.repos.d/_copr*yuezk*globalprotect-openconnect*.repo" >/dev/null; then
    echo "COPR already enabled: $COPR_REPO"
else
    echo "Enabling COPR: $COPR_REPO"
    sudo dnf copr enable -y "$COPR_REPO"
fi

# Install the client (pulls in openconnect).
sudo dnf install -y "$PKG"

echo
echo "Installed $(rpm -q "$PKG")."
echo "Usage:"
echo "  GUI : launch 'GlobalProtect' from your app menu"
echo "  CLI : gpclient connect <portal.yourcompany.com>"
