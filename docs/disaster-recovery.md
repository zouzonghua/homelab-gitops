# 灾难恢复

## 恢复顺序

1. 恢复物理网络、PVE 存储和管理入口。
2. 人工恢复 OPNsense/RouterOS 等网络核心。
3. 恢复普通 VM/LXC，并用 Ansible 配置系统。
4. 恢复 K3s 控制面与 Flux。
5. 由 Flux 恢复基础组件和应用。

## 最低备份要求

- PVE、路由器和防火墙配置备份需加密并存放在仓库外的备份位置。
- OpenTofu State 需加密、备份并按站点隔离。
- SOPS age 私钥不得提交到本仓库。
- 恢复步骤发生变化时，同一 Pull Request 必须更新本文档。

具体设备命令待完成现场 Inventory 后补充。
