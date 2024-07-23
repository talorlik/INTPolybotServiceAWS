#!/bin/bash

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

apt-get update

# Packages to check and install
packages=("libc6" "groff" "less" "unzip" "curl", "ca-certificates", "gnupg")

for package in "${packages[@]}"; do
    install_if_missing "$package"
done

# Check is Docker is installed and if not install it
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key:
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    groupadd docker
    usermod -aG docker $USER
    newgrp docker
    systemctl enable docker.service
    systemctl enable containerd.service
    # Write Docker daemon configuration
    tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

    # Restart Docker to apply the new configuration
    systemctl restart docker
fi

if ! systemctl is-active --quiet docker; then
    systemctl start docker
fi

# Check if AWS Cli is installed and if not install and verify it
if ! command -v aws &> /dev/null; then
    local certificate=$(cat <<'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----

mQINBF2Cr7UBEADJZHcgusOJl7ENSyumXh85z0TRV0xJorM2B/JL0kHOyigQluUG
ZMLhENaG0bYatdrKP+3H91lvK050pXwnO/R7fB/FSTouki4ciIx5OuLlnJZIxSzx
PqGl0mkxImLNbGWoi6Lto0LYxqHN2iQtzlwTVmq9733zd3XfcXrZ3+LblHAgEt5G
TfNxEKJ8soPLyWmwDH6HWCnjZ/aIQRBTIQ05uVeEoYxSh6wOai7ss/KveoSNBbYz
gbdzoqI2Y8cgH2nbfgp3DSasaLZEdCSsIsK1u05CinE7k2qZ7KgKAUIcT/cR/grk
C6VwsnDU0OUCideXcQ8WeHutqvgZH1JgKDbznoIzeQHJD238GEu+eKhRHcz8/jeG
94zkcgJOz3KbZGYMiTh277Fvj9zzvZsbMBCedV1BTg3TqgvdX4bdkhf5cH+7NtWO
lrFj6UwAsGukBTAOxC0l/dnSmZhJ7Z1KmEWilro/gOrjtOxqRQutlIqG22TaqoPG
fYVN+en3Zwbt97kcgZDwqbuykNt64oZWc4XKCa3mprEGC3IbJTBFqglXmZ7l9ywG
EEUJYOlb2XrSuPWml39beWdKM8kzr1OjnlOm6+lpTRCBfo0wa9F8YZRhHPAkwKkX
XDeOGpWRj4ohOx0d2GWkyV5xyN14p2tQOCdOODmz80yUTgRpPVQUtOEhXQARAQAB
tCFBV1MgQ0xJIFRlYW0gPGF3cy1jbGlAYW1hem9uLmNvbT6JAlQEEwEIAD4CGwMF
CwkIBwIGFQoJCAsCBBYCAwECHgECF4AWIQT7Xbd/1cEYuAURraimMQrMRnJHXAUC
ZMKcEgUJCSEf3QAKCRCmMQrMRnJHXCilD/4vior9J5tB+icri5WbDudS3ak/ve4q
XS6ZLm5S8l+CBxy5aLQUlyFhuaaEHDC11fG78OduxatzeHENASYVo3mmKNwrCBza
NJaeaWKLGQT0MKwBSP5aa3dva8P/4oUP9GsQn0uWoXwNDWfrMbNI8gn+jC/3MigW
vD3fu6zCOWWLITNv2SJoQlwILmb/uGfha68o4iTBOvcftVRuao6DyqF+CrHX/0j0
klEDQFMY9M4tsYT7X8NWfI8Vmc89nzpvL9fwda44WwpKIw1FBZP8S0sgDx2xDsxv
L8kM2GtOiH0cHqFO+V7xtTKZyloliDbJKhu80Kc+YC/TmozD8oeGU2rEFXfLegwS
zT9N+jB38+dqaP9pRDsi45iGqyA8yavVBabpL0IQ9jU6eIV+kmcjIjcun/Uo8SjJ
0xQAsm41rxPaKV6vJUn10wVNuhSkKk8mzNOlSZwu7Hua6rdcCaGeB8uJ44AP3QzW
BNnrjtoN6AlN0D2wFmfE/YL/rHPxU1XwPntubYB/t3rXFL7ENQOOQH0KVXgRCley
sHMglg46c+nQLRzVTshjDjmtzvh9rcV9RKRoPetEggzCoD89veDA9jPR2Kw6RYkS
XzYm2fEv16/HRNYt7hJzneFqRIjHW5qAgSs/bcaRWpAU/QQzzJPVKCQNr4y0weyg
B8HCtGjfod0p1A==
=gdMc
-----END PGP PUBLIC KEY BLOCK-----
EOF
    )

    echo "$certificate" > awscliv2.gpg

    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    if [ $? -ne 0 ]; then
        echo "Failed to download AWS CLI"
        exit 1
    fi

    gpg --import awscliv2.gpg
    if [ $? -ne 0 ]; then
        echo "Failed to import GPG key"
        exit 1
    fi

    curl -o awscliv2.sig https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip.sig
    if [ $? -ne 0 ]; then
        echo "Failed to download AWS CLI signature"
        exit 1
    fi

    # Verify the signature
    gpg_output=$(gpg --verify awscliv2.sig awscliv2.zip 2>&1)
    if echo "$gpg_output" | grep -iq "good signature"; then
        echo "GPG verification successful"
    else
        echo "GPG verification failed"
        echo "$gpg_output"
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