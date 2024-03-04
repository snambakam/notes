# How to update the display resolution for Ubuntu VM on HyperV

1. Edit /etc/default/grub

```bash
sudo vi /etc/default/grub
```

1. Set GRUB_CMDLINE_LINUX to "quiet splash video=hyperv_fb:3840x2160"

1. sudo update-grub

1. sudo apt install linux-image-extra-virtual

1. On your Windows System, open a PowerShell command Window with Admin privileges and type the following. Choose the maximum resolution values supported on your display.

```powershell
set-vmvideo -vmname ubuntu -horizontalresolution:3840 -verticalresolution:2160 -resolutiontype single
```
