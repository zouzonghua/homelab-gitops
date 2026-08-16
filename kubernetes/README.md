# Kubernetes

集群采用 K3s 发行版，使用 Flux 实现 GitOps。

- `clusters/`：每个站点的 Flux Bootstrap 与同步入口
- `applications/`：可复用的应用声明
