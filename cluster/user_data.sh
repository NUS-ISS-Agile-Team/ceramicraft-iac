#!/bin/bash
set -e

# 1. 更新系统并安装 containerd（K3s 官方推荐，无需 Docker）
sudo apt-get update -qq
sudo apt-get install -y containerd apt-transport-https ca-certificates curl

server_url='${server_url}'
node_token='${node_token}'
# 2. 设置 K3s 安装参数
export K3S_URL="${server_url}"
export K3S_TOKEN="${node_token}"
export K3S_ROLE=agent
export INSTALL_K3S_EXEC="--node-label az=ap-southeast-1c"
export INSTALL_K3S_VERSION="v1.32.0+k3s1"
export INSTALL_K3S_SKIP_DOWNLOAD=false
export INSTALL_K3S_FORCE_RESTART=true 

# 3. 一键安装 K3s agent
curl -sfL https://get.k3s.io | sh -

# 4. 开机自启已默认启用，无需额外 systemctl enable