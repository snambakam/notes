# Fix display resolution issue on Ubuntu

1. Ensure necessary packages are installed

```bash
sudo apt update
sudo apt install -y \
    ubuntu-desktop \
    gnome-session \
    gdm3 \
    xserver-xorg-video-fbdev
sudo dpkg-reconfigure gdm3
sudo apt install linux-image-generic
sudo update-initramfs -u
sudo reboot
```

1. Disable Wayland

Edit /etc/gdm3/custom.conf and uncomment "WaylandEnable=false"

```bash
sudo systemctl restart gdm3
```

