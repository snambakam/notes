# Kernel Development Notes

## Basic Developer Iterative loop

1. make -j$(nproc)
1. make -j$(nproc) modules
1. make modules_install
1. make install
1. reboot

## Kernel Signing

Either turn off secure boot in the bios or sign using private key that is enlisted with the MOK (Machine Owner Key) Manager.

### 1. Create key
```bash
openssl req -new -x509 -newkey rsa:2048 \
  -keyout MOK.key -out MOK.crt -nodes -days 3650 \
  -subj "/CN=Custom Kernel/"
```

### 2. Enroll key
```bash
sudo mokutil --import MOK.crt
```

### 3. Reboot
```bash
sudo reboot now
```
Note: enroll key in MOK Manager UI

### 4. After every kernel build
```bash
sbsign --key MOK.key --cert MOK.crt \
  /boot/vmlinuz-$(make kernelrelease)
```
Note: Update grub and reboot
