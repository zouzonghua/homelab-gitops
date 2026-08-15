# 成都 Argo CD

Argo CD 运行在成都 K3s 集群的 `argocd` Namespace。安装清单固定到 Argo CD `v3.2.12`，便于审核和复现。

首次 Bootstrap 仍需由本地 `kubectl` 执行：

```bash
export KUBECONFIG=~/.kube/homelab-chengdu.yaml
kubectl apply -k kubernetes/clusters/chengdu/argocd
```

确认 Argo CD 正常后，再提交 `Application` 让它从 Git 管理自身和成都应用。不要把管理员密码或 Kubeconfig 写入仓库。
