#!/usr/bin/env bash
set -euo pipefail

InstallRequiredPackages() {
    # Fedora: pcscd is provided by pcsc-lite package [1](https://packages.fedoraproject.org/pkgs/pcsc-lite/pcsc-lite/)
    # Fedora: modutil/certutil are provided by nss-tools [2](https://learn.microsoft.com/en-us/entra/identity/devices/sso-linux)
    sudo dnf install -y \
        pcsc-lite \
        pcsc-lite-ccid \
        opensc \
        nss-tools \
        openssl \
        yubikey-manager

    # Ensure pcscd is enabled and running (required for CCID/smartcard features)
    sudo systemctl enable --now pcscd
}

ConfigureSmartcardSettingsForUser() {
    local NSSDB_DIR="${HOME}/.pki/nssdb"

    mkdir -p "${NSSDB_DIR}"
    chmod 700 "${HOME}/.pki"
    chmod 700 "${NSSDB_DIR}"

    # Create (or ensure) the NSS DB exists
    modutil -force -create -dbdir "sql:${NSSDB_DIR}"

    # Fedora places PKCS#11 modules under %{_libdir}/pkcs11/ (often /usr/lib64/pkcs11/) [3](https://docs.fedoraproject.org/en-US/packaging-guidelines/Pkcs11Support/)
    # Find OpenSC PKCS#11 module robustly across Fedora variants.
    local OPENSC_PKCS11=""
    for candidate in \
        /usr/lib64/pkcs11/opensc-pkcs11.so \
        /usr/lib/pkcs11/opensc-pkcs11.so \
        /usr/lib64/opensc-pkcs11.so \
        /usr/lib/opensc-pkcs11.so
    do
        if [[ -r "${candidate}" ]]; then
            OPENSC_PKCS11="${candidate}"
            break
        fi
    done

    if [[ -z "${OPENSC_PKCS11}" ]]; then
        echo "ERROR: Could not find opensc-pkcs11.so on this system." >&2
        echo "Hint: Ensure 'opensc' is installed, then locate it with:" >&2
        echo "  rpm -ql opensc | grep opensc-pkcs11.so" >&2
        exit 1
    fi

    # Add the smart card module to the user's NSS database
    modutil -force \
        -dbdir "sql:${NSSDB_DIR}" \
        -add 'SC Module' \
        -libfile "${OPENSC_PKCS11}"
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
INSTALL_PACKAGES=0
CONFIGURE_USER_ENV=0

optstring="ich"

while getopts "${optstring}" arg; do
  case "${arg}" in
    h)
      ShowUsage
      exit 0
      ;;
    i)
      INSTALL_PACKAGES=1
      ;;
    c)
      CONFIGURE_USER_ENV=1
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

if [[ "${INSTALL_PACKAGES}" -eq 1 ]]; then
    InstallRequiredPackages
fi

if [[ "${CONFIGURE_USER_ENV}" -eq 1 ]]; then
    ConfigureSmartcardSettingsForUser
fi

