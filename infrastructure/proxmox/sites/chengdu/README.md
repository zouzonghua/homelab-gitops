# 成都 PVE

本目录通过 OpenTofu 创建：

- `400 tpl-vm-debian`
- `120 cd-k3s-server-01`（`10.10.10.70/24`）
- `121 cd-k3s-server-02`（`10.10.10.71/24`）
- `122 cd-k3s-server-03`（`10.10.10.72/24`）

三台 VM 暂时使用 `pve_share`，每台配置为 2 vCPU、2GB 内存和 32GB 磁盘。`10.10.10.69` 仅预留给后续 kube-vip，不由本层创建。

VMID、名称、地址和启动顺序读取自仓库根目录 `inventory/`；不要在本目录重复维护节点清单。Debian Cloud Image 固定到 `20260810-2566` 并校验官方 SHA-512。

## 前置条件

1. 在 OPNsense 中保留 `10.10.10.69–73`，排除 DHCP 动态分配。
2. 创建最小权限 PVE API Token，至少允许下载镜像、创建模板和管理 VM。
3. 确认 `pve_share` 已启用 `Import` 与 `Disk image` 内容类型。
4. 将 `terraform.tfvars.example` 复制为 `terraform.tfvars`，写入 SSH 公钥。

API Token 只通过环境变量提供：

```bash
export PROXMOX_VE_API_TOKEN='opentofu@pve!provider=<token-secret>'
```

## 执行

```bash
tofu init
tofu fmt -check
tofu validate
tofu plan -out=chengdu.tfplan
tofu show chengdu.tfplan
tofu apply chengdu.tfplan
```

Apply 会创建并启动三台 VM。执行前必须确认 Plan 不修改或删除 VMID `100`、`110` 及现有 LXC。

模板和 K3s VM 均启用 `prevent_destroy`，同时禁用销毁时自动清理磁盘。确需销毁时必须先修改代码，并在独立维护窗口再次审查 Plan。

## 当前边界

- 尚未安装 K3s、kube-vip、Cilium 或 Flux。
- QEMU Guest Agent 将由后续系统初始化层安装，当前 Provider 不等待 Agent。
- OpenTofu State 不提交 Git；正式使用前需要确定加密的远程 State 与备份方案。
