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

确认 Argo CD 正常并完成 Git 仓库认证后，应用上级 `kubernetes/clusters/chengdu/`，让 Argo CD 管理自身和成都配置。不要把管理员密码或 Kubeconfig 写入仓库。
