#!/bin/bash
set -ex
exec > >(tee /var/log/userdata.log) 2>&1

# 1. 装 k3s：禁用 traefik/servicelb，开 NodePort 范围 30000-30100
curl -sfL https://get.k3s.io | sh -s - \
  --disable traefik \
  --disable servicelb \
  --disable metrics-server \
  --kubelet-arg="allowed-unsafe-sysctls=net.ipv4.ip_forward" \
  --tls-san $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)

until sudo ss -tnlp | grep -q :6443; do sleep 3; done

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
chmod 644 /etc/rancher/k3s/k3s.yaml
echo 'export KUBECONFIG=/etc/rancher/k3s/k3s.yaml' >> /etc/profile

# 2. 装 Helm
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 3. 装 ArgoCD（slim 版）
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 4. 改 ArgoCD server 为 NodePort 30080
kubectl patch svc argocd-server -n argocd -p '{"spec":{"type":"NodePort","ports":[{"name":"http","port":80,"nodePort":30080,"targetPort":8080}]}}'

# 6. 等待 ArgoCD 可用
kubectl -n argocd wait deploy/argocd-server --for=condition=Available --timeout=300s
sleep 10
ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "$ARGOCD_PASSWORD" > /tmp/argocd-password.txt

# 7. GitOps：让 ArgoCD 自己拉 Git 配置（仓库可以是已有工程里的子目录）
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/lianjin/git-ops.git
    targetRevision: HEAD
    path: .
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated: {prune: true, selfHeal: true}
EOF