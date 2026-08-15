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

## 创建 PVE API Token

在 PVE Shell 中创建专用用户，不使用 `root@pam` Token：

```bash
pveum user add opentofu@pve \
  --comment "OpenTofu managed infrastructure"
```

创建当前配置所需的最小权限角色：

```bash
pveum role add OpenTofuK3s --privs \
"Datastore.Allocate Datastore.AllocateSpace Datastore.AllocateTemplate Datastore.Audit SDN.Use Sys.AccessNetwork Sys.Audit Sys.Modify VM.Allocate VM.Audit VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.PowerMgmt"
```

将角色授予专用用户：

```bash
pveum acl modify / \
  --user opentofu@pve \
  --role OpenTofuK3s
```

创建继承该用户权限的 API Token：

```bash
pveum user token add opentofu@pve provider \
  --privsep=0 \
  --comment "homelab-gitops"
```

Token Secret 仅显示一次，应立即保存到密码管理器。不要将其发到聊天、写入 `terraform.tfvars` 或提交 Git。

在执行 OpenTofu 的本机终端安全输入 Secret：

```bash
read -s PROXMOX_TOKEN_SECRET
export PROXMOX_VE_API_TOKEN="opentofu@pve!provider=${PROXMOX_TOKEN_SECRET}"
unset PROXMOX_TOKEN_SECRET
```

验证 Token 可以读取 PVE API：

```bash
curl -sk \
  -H "Authorization: PVEAPIToken=${PROXMOX_VE_API_TOKEN}" \
  https://10.10.10.2:8006/api2/json/version
```

检查用户、Token 和 ACL：

```bash
pveum user list
pveum user token list opentofu@pve
pveum acl list
```

若 OpenTofu 返回 `403 Permission check failed`，应根据错误补充单项权限，不要直接改用 `Administrator`。

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
