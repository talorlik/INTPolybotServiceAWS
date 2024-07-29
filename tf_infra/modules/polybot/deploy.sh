#!/bin/bash

su - ubuntu

# Function to check if a package is installed
is_installed() {
    dpkg -l | grep -q "^ii  $1"
}

# Function to install a package if it is not installed
install_if_missing() {
    if ! is_installed "$1"; then
        echo "Installing $1..."
        sudo apt-get install -y "$1"
    else
        echo "$1 is already installed."
    fi
}

sudo apt-get update

# Packages to check and install
for package in libc6 groff less unzip curl ca-certificates gnupg; do
    install_if_missing "$package"
done

# Check is Docker is installed and if not install it
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key:
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc > /dev/null
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
    su - $USER
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
    # Write Docker daemon configuration
    sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

    # Restart Docker to apply the new configuration
    sudo systemctl restart docker
fi

if ! sudo systemctl is-active --quiet docker; then
    sudo systemctl start docker
fi

# Check if AWS Cli is installed and if not install and verify it
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    if [ $? -ne 0 ]; then
        echo "Failed to download AWS CLI"
        exit 1
    fi

    unzip awscliv2.zip
    if [ $? -ne 0 ]; then
        echo "Failed to unzip AWS CLI"
        exit 1
    fi

    sudo ./aws/install
    if [ $? -ne 0 ]; then
        echo "Failed to install AWS CLI"
        exit 1
    fi

    aws --version
    if [ $? -ne 0 ]; then
        echo "AWS CLI installation verification failed"
        exit 1
    fi
fi