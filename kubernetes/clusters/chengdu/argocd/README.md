# 成都 Argo CD

Argo CD 运行在成都 K3s 集群的 `argocd` Namespace。安装清单固定到 Argo CD `v3.5.1`，便于审核和复现。

首次 Bootstrap 仍需由本地 `kubectl` 执行：

```bash
export KUBECONFIG=~/.kube/homelab-chengdu.yaml
kubectl apply --server-side --force-conflicts \
  -k kubernetes/clusters/chengdu/argocd

kubectl -n argocd get pods
kubectl -n argocd rollout status deployment/argocd-server --timeout=300s
```

`kustomization.yaml` 会从固定版本的官方 URL 拉取安装清单。Argo CD 的 CRD 较大，Bootstrap 必须使用 Server-Side Apply，避免客户端 `last-applied-configuration` 注解超过 Kubernetes 限制。

保持一个终端运行端口转发：

```bash
kubectl -n argocd port-forward svc/argocd-server 8443:443
```

在另一个终端登录 Argo CD，并添加 GitHub 私有仓库认证：

```bash
export KUBECONFIG=~/.kube/homelab-chengdu.yaml
ARGOCD_INITIAL_PASSWORD="$(argocd admin initial-password -n argocd | head -n 1)"

argocd login localhost:8443 \
  --username admin \
  --password "$ARGOCD_INITIAL_PASSWORD" \
  --insecure

unset ARGOCD_INITIAL_PASSWORD

argocd repo add \
  ssh://git@github.com/zouzonghua/homelab-gitops.git \
  --ssh-private-key-path "$HOME/.ssh/id_ed25519_argocd_homelab"

argocd repo list
```

仓库状态为 `Successful` 后，创建成都根 Application，让 Argo CD 接管上级目录：

```bash
kubectl apply --server-side \
  -f kubernetes/clusters/chengdu/argocd-application.yaml

argocd app list
```

不要把管理员密码、SSH 私钥或 Kubeconfig 写入仓库。
