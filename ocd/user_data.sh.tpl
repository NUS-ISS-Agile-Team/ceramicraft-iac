#!/bin/bash
set -xe

# Simple bootstrap for Amazon Linux 2 to install docker, git and docker-compose
# then clone the repo and run docker-compose up -d

REPO_URL="${repo_url}"
REPO_BRANCH="${repo_branch}"
REPO_DIR="${repo_dir}"
COMPOSE_PATH="${compose_path}"

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
  DOCKER_COMPOSE_VERSION="v2.17.3"
  curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
fi

# Ensure home dir ownership
chown -R ec2-user:ec2-user /home/ec2-user

cd /home/ec2-user
if [ -d "${REPO_DIR}" ]; then
  cd "${REPO_DIR}"
  sudo -u ec2-user git fetch --all || true
  sudo -u ec2-user git checkout "${REPO_BRANCH}" || true
  sudo -u ec2-user git pull origin "${REPO_BRANCH}" || true
else
  sudo -u ec2-user git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${REPO_DIR}" || true
  cd "${REPO_DIR}"
fi

cd "${REPO_DIR}/${COMPOSE_PATH}"
sudo -u ec2-user docker-compose up -d || sudo -u ec2-user /usr/local/bin/docker-compose up -d

exit 0
