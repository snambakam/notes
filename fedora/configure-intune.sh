#!/bin/bash

set -eou pipefail

InstallRequiredPackages() {
	# Install Smartcard drivers and YubiKey support
	sudo dnf install -y \
		pcscd \
		yubikey-manager
	# Install YubiKey/Edge Bridge components
	sudo dnf install -y \
		opensc \
		libnss3-tools \
		openssl
}

ConfigureSmartcardSettingsForUser() {
	mkdir -p $HOME/.pki/nssdb
	chmod 700 $HOME/.pki
	chmod 700 $HOME/.pki/nssdb
	modutil -force \
		-create \
		-dbdir sql:$HOME/.pki/nssdb
	modutil -force \
		-dbdir sql:$HOME/.pki/nssdb \
		-add 'SC Module' \
		-libfile /usr/lib/x86_64-linux-gnu/pkcs11/opensc-pkcs11.so
}

ShowUsage() {
	echo "Usage: $0 [-c] [-i]"
        echo "    -c : Configure User environment"
        echo "    -i : Install pre-requisite packages"
}

#
# Main
#

local INSTALL_PACKAGES=0
local CONFIGURE_USER_ENV=0

optstring="ich"

while getopts ${optstring} arg; do
  case ${arg} in
    h)
      showUsage
      exit 0
      ;;
    i)
      INSTALL_PACKAGES=1
      ;;
    c)
      CONFIGURE_USER_ENV=1
      ;;
    :)
      echo "$0: Must supply an argument to -$OPTARG." >&2
      exit 1
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
      ;;
  esac
done

if [ $INSTALL_PACKAGES -eq 1 ]; then
	InstallRequiredPackages
fi

if [ $CONFIGURE_USER_ENV -eq 1 ]; then
	ConfigureSmartcardSettingsForUser
fi

