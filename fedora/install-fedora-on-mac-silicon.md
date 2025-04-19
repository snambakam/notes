# Install a Fedora VM on Macbook Pro (Silicon)

1. Download [Fedora ISO](https://download.fedoraproject.org/pub/fedora/linux/releases/41/Everything/aarch64/iso/Fedora-Everything-netinst-aarch64-41-1.4.iso)
1. Create a VM using VMware Fusion with the ISO
1. Start the VM, Login and run the following commands.
    1. sudo dnf group install gnome-desktop
    1. sudo dnf install switchdesk switchdesk-gui
    1. sudo systemctl set-default graphical.target
    1. sudo reboot
