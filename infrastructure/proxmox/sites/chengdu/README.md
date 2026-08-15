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

## 配置 SSH 公钥

`ssh_public_key` 是本机 SSH 密钥对中的公钥。OpenTofu 通过 Cloud-init 将它写入三台 Debian VM 的 `ops` 用户，用于无密码登录：

```bash
ssh -i ~/.ssh/id_ed25519_homelab ops@10.10.10.70
```

私钥始终保留在本机，不能写入仓库或发送到 PVE。先检查本机已有公钥：

```bash
ls -1 ~/.ssh/*.pub
```

若没有适合 Homelab 的密钥，创建独立的 Ed25519 密钥：

```bash
ssh-keygen -t ed25519 -a 64 \
  -f ~/.ssh/id_ed25519_homelab \
  -C "zonghua@homelab"
```

复制示例文件：

```bash
cp terraform.tfvars.example terraform.tfvars
```

查看公钥并将完整单行内容填入 `terraform.tfvars`：

```bash
cat ~/.ssh/id_ed25519_homelab.pub
```

```hcl
ssh_public_key = "ssh-ed25519 AAAA... zonghua@homelab"
```

`terraform.tfvars` 已被 `.gitignore` 排除。这里只能填写 `.pub` 公钥，不能填写没有 `.pub` 后缀的私钥。

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

在执行 OpenTofu 的本机 zsh 终端安全输入 Secret。固定前缀使用单引号，避免 `!provider` 触发 zsh 历史展开：

```zsh
read -rs 'PROXMOX_TOKEN_SECRET?Token Secret: '
export PROXMOX_VE_API_TOKEN='opentofu@pve!provider='"${PROXMOX_TOKEN_SECRET}"
unset PROXMOX_TOKEN_SECRET
```

确认变量存在，但不要输出其内容：

```zsh
[[ -n "$PROXMOX_VE_API_TOKEN" ]] && echo "Token 已设置"
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

模板和 K3s VM 均启用静态 `prevent_destroy = true`，同时默认不自动清理未引用磁盘。确需销毁时必须在独立维护窗口临时修改 K3s VM 资源，并再次审查 Plan。

## 当前边界

- 尚未安装 Argo CD 或 Cilium。
- QEMU Guest Agent 将由后续系统初始化层安装，当前 Provider 不等待 Agent。
- OpenTofu State 不提交 Git；正式使用前需要确定加密的远程 State 与备份方案。
