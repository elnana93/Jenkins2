#!/bin/bash
set -euxo pipefail

# Build yum cache (more reliable on first boot than dnf update)
dnf -y makecache

# Install core tools (DO NOT install 'curl' on AL2023 to avoid curl-minimal conflict)
dnf install -y git unzip wget python3 python3-pip java-17-amazon-corretto docker

# Ensure curl exists (AL2023 usually includes curl-minimal already)
if ! command -v curl >/dev/null 2>&1; then
  dnf install -y curl-minimal
fi

# Docker
systemctl enable --now docker
usermod -aG docker ec2-user || true

# Terraform
TERRAFORM_VERSION="1.14.3"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) TF_ARCH="amd64" ;;
  aarch64|arm64) TF_ARCH="arm64" ;;
  *) echo "Unsupported arch: $ARCH" ; exit 1 ;;
esac

curl -fsSL -o /tmp/terraform.zip \
  "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_${TF_ARCH}.zip"
unzip -o /tmp/terraform.zip -d /usr/local/bin
chmod +x /usr/local/bin/terraform
rm -f /tmp/terraform.zip

# AWS CLI v2 (skip if already installed)
if ! command -v aws >/dev/null 2>&1; then
  case "$ARCH" in
    x86_64) AWS_ARCH="x86_64" ;;
    aarch64|arm64) AWS_ARCH="aarch64" ;;
  esac

  curl -fsSL -o /tmp/awscliv2.zip "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip"
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install --update
  rm -rf /tmp/aws /tmp/awscliv2.zip
fi

# Jenkins
wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
dnf install -y jenkins

# Optional: let Jenkins run docker commands (common for pipelines)
usermod -aG docker jenkins || true

systemctl enable --now jenkins
systemctl restart jenkins || true
