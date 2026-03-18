#!/usr/bin/env bash
set -euo pipefail

Install_ykcs11_p11kit_module() {
    if [ ! -f /usr/share/p11-kit/modules/ykcs11.module ]; then
        sudo tee /usr/share/p11-kit/modules/ykcs11.module <<-'EOF'
		module: libykcs11.so
		priority: 50
EOF
    fi
}

InstallRequiredPackages() {
    echo "INFO: Installing pre-requisite packages..."
    # Fedora: pcscd is provided by pcsc-lite package [1](https://packages.fedoraproject.org/pkgs/pcsc-lite/pcsc-lite/)
    # Fedora: modutil/certutil are provided by nss-tools [2](https://learn.microsoft.com/en-us/entra/identity/devices/sso-linux)
    sudo dnf install -y \
        pcsc-lite \
        pcsc-lite-ccid \
        pcsc-tools \
        opensc \
        nss-tools \
        openssl \
        yubikey-manager \
        yubico-piv-tool

    # Ensure pcscd is enabled and running (required for CCID/smartcard features)
    sudo systemctl enable --now pcscd

    Install_ykcs11_p11kit_module() 
}

ConfigureSmartcardSettingsForUser() {
    local NSSDB_DIR="${HOME}/.pki/nssdb"

    echo "INFO: Configuring settings for user..."

    mkdir -p "${NSSDB_DIR}"
    chmod 700 "${HOME}/.pki" "${NSSDB_DIR}"

    # Create NSS DB (used by NSS apps for cert/key storage)
    modutil -force -create -dbdir "sql:${NSSDB_DIR}"

    # On Fedora, PKCS#11 providers should be registered via p11-kit,
    # not added per-user with modutil, to avoid duplicate registration. [3](https://docs.fedoraproject.org/en-US/packaging-guidelines/Pkcs11Support/)[1](https://github.com/dogtagpki/pki/issues/3208)

    # Verify OpenSC is registered with p11-kit (usually installed as opensc.module).
    if [[ -r /usr/share/p11-kit/modules/opensc.module ]]; then
        echo "Found p11-kit OpenSC module config: /usr/share/p11-kit/modules/opensc.module"
    elif [[ -d /usr/share/p11-kit/modules ]]; then
        echo "WARNING: /usr/share/p11-kit/modules exists but opensc.module not found."
        echo "If OpenSC is installed, check with: p11-kit list-modules | grep -i opensc"
    else
        echo "WARNING: p11-kit modules directory not found at /usr/share/p11-kit/modules."
    fi

    # Optional visibility checks (won't fail the script if no token inserted)
    if command -v p11-kit >/dev/null 2>&1; then
        echo "p11-kit configured modules (filtered):"
        p11-kit list-modules 2>/dev/null | grep -i -E 'opensc|pkcs11' || true

        echo "Available tokens:"
        p11-kit list-tokens pkcs11:token 2>/dev/null || true
    fi
}

ShowUsage() {
    echo "Usage: $0 [-c] [-i] [-h]"
    echo "    -c : Configure user environment (NSS DB + OpenSC PKCS#11 module)"
    echo "    -i : Install prerequisite packages"
    echo "    -h : Show this help"
}

#
# Main
#

optstring="ich"

while getopts "${optstring}" arg; do
  case "${arg}" in
    h)
      ShowUsage
      exit 0
      ;;
    i)
      InstallRequiredPackages
      exit 0
      ;;
    c)
      ConfigureSmartcardSettingsForUser
      exit 0
      ;;
    :)
      echo "$0: Must supply an argument to -${OPTARG}." >&2
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}." >&2
      ShowUsage
      exit 2
      ;;
  esac
done

InstallRequiredPackages
ConfigureSmartcardSettingsForUser

