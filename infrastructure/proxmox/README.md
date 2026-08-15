# Proxmox

按站点隔离 OpenTofu 配置与 State。当前站点：

- `sites/chengdu/`：成都 PVE 与 K3s Server VM

所有变更先执行 `tofu plan` 并人工审查；仓库不提供自动 Apply 工作流。
