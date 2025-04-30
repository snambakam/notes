# Setup Developer Environment on Ubuntu

1. Install common developer utilities

```bash
sudo apt install -y \
    autoconf \
    automake \
    clang \
    cmake \
    curl \
    git \
    gcc \
    g++ \
    gdb \
    libtool \
    meld \
    net-tools \
    openssh-server \
    wget

```

1. Install Docker

```bash
# Remove old versions
sudo apt remove docker docker.io containerd runc
# Install pre-requisites
sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
# Setup Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# Install Docker Engine
sudo apt update
sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
# Start and Enable Docker
sudo systemctl enable docker
sudo systemctl start docker
usermod -aG docker $USER
```

1. Setup git-credential-manager

```bash
sudo apt install -y \
    git \
    gnupg \
    pass
wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.0/gcm-linux_amd64.2.6.0.deb
sudo dpkg -i gcm-linux_amd64.deb
git config --global credential.helper manager
#git config --global user.name "Your Name"
#git config --global user.email "email@domain.com"
```

1. Setup password storage for GCM

```bash
gpg --full-generate-key
gpg --list-secret-keys --keyid-format LONG
pass init <YOUR-GPG-ID>
```