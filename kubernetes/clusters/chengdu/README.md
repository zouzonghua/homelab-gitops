# 成都 Flux

Flux 通过 GitHub Deploy Key 读取本仓库，并持续同步成都 K3s 集群。集群不额外安装管理 UI。

首次 Bootstrap：

```bash
brew install fluxcd/tap/flux
export KUBECONFIG="$HOME/.kube/homelab-chengdu.yaml"
flux check --pre

read -rs 'GITHUB_TOKEN?GitHub Token: '
export GITHUB_TOKEN
flux bootstrap github \
  --token-auth=false \
  --owner=zouzonghua \
  --repository=homelab-gitops \
  --branch=main \
  --path=kubernetes/clusters/chengdu \
  --personal
unset GITHUB_TOKEN
git pull --ff-only origin main
```

Fine-grained PAT 需要仓库 `Administration` 和 `Contents` 读写权限。PAT 仅用于 Bootstrap，不写入仓库或集群；完成后 Flux 使用仓库只读 Deploy Key。

验证：

```bash
flux check
flux get sources git
flux get kustomizations
flux get helmreleases -A
```
