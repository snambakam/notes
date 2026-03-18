# KVM Setup on Fedora

```
sudo dnf install -y \
    libvirt-daemon \
    qemu \
    virt-manager
```

## Checkout Kernel Sources

```bash
git clone https://src.fedoraproject.org/rpms/kernel.git
cd kernel
git switch f43
```
