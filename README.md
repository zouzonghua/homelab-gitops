# homelab-gitops

家庭 Homelab 多站点的统一设计、配置事实源与变更审计仓库。

## 管理范围

- `inventory/`：站点、网络、主机与服务的唯一事实源
- `infrastructure/`：OpenTofu 与 Ansible 基础设施代码
- `kubernetes/`：K3s 集群与 Argo CD 应用声明
- `docs/`：架构、地址规划和灾难恢复文档
- `secrets/`：仅保存 SOPS 加密后的敏感配置

## 自动化边界

| 对象 | 管理方式 |
| --- | --- |
| 地址、VLAN、DNS、路由设计 | Git 作为事实源 |
| 普通 VM/LXC | OpenTofu，人工审批后执行 |
| Debian/K3s 节点 | Ansible 初始化 |
| Kubernetes 应用 | Argo CD 同步 |
| PVE 网络、OPNsense、存储 | 只记录设计和恢复步骤，人工变更 |

## 使用原则

1. 先更新 `inventory/`，再修改具体站点或应用配置。
2. 不提交密码、Token、私钥、Kubeconfig 和未加密备份。
3. OpenTofu State 不进入 Git，各站点使用独立 State。
4. 涉及网络出口、存储或数据的变更必须人工审核。

当前处于初始化阶段：先维护设计、Inventory 和恢复资料，暂不自动 Apply。
