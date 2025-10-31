#!/bin/bash
set -xe

# Simple bootstrap for Amazon Linux 2 to install docker, git and docker-compose
# then clone the repo and run docker-compose up -d

cd /home/ec2-user
yum update -y

# Install docker
if ! command -v docker >/dev/null 2>&1; then
  yum install -y docker || true
fi
service docker start
usermod -a -G docker ec2-user || true

# Install git
if ! command -v git >/dev/null 2>&1; then
  yum install -y git
fi

# Install docker-compose (v2 binary)
if ! command -v docker-compose >/dev/null 2>&1; then
  curl -L "https://github.com/docker/compose/releases/download/v2.17.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

# Ensure home dir ownership
chown -R ec2-user:ec2-user /home/ec2-user

cd /home/ec2-user
if [ -d "${repo_dir}" ]; then
  cd "${repo_dir}"
  sudo -u ec2-user git fetch --all || true
  sudo -u ec2-user git checkout "${repo_branch}" || true
  sudo -u ec2-user git pull origin "${repo_branch}" || true
else
  sudo -u ec2-user git clone --recursive --branch "${repo_branch}" "${repo_url}" "${repo_dir}" || true
  cd "${repo_dir}"
fi

cd "${compose_path}"
sudo -u ec2-user docker-compose up -d || sudo -u ec2-user /usr/local/bin/docker-compose up -d

exit 0
