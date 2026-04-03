# Intune Enrollment on Ubuntu

## Issues

### Local user login requires Yubikey

```bash
sudo update-alternatives --config gdm-smartcard
```

Note: choose sssd-or-password option
