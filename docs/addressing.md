# 地址规划

当前规划以 `inventory/sites.yaml` 和 `inventory/vlans.yaml` 为准。

## 分配规则

- 家庭多站点使用 `10.10.0.0/16`。
- 每个家庭站点预留一个 `/20` 地址块。
- WireGuard Overlay 使用独立地址段。
- 新增地址前必须检查站点、VLAN、主机和静态租约，避免重复。

尚未现场确认的地址应标记为 `planned`，不能作为已部署事实。
