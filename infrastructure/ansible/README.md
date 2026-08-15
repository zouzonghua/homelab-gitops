# Ansible

用于普通 Linux 主机和 K3s 节点的可重复配置。主机与 VIP 信息读取仓库根目录 `inventory/`，不在 Ansible 中重复维护。

## 成都 K3s HA 集群

先确认 Python 版本不低于 3.11，再安装依赖：

```bash
cd infrastructure/ansible
python3 --version
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

三台节点统一使用 `ops` SSH 用户，公钥由 Cloud-init 写入，Ansible 通过 sudo 执行系统任务。

首次执行时生成 Token，并持久化到 Git 仓库外。后续执行必须复用同一个文件，不要重新生成：

```bash
mkdir -p ~/.config/homelab-gitops
chmod 700 ~/.config/homelab-gitops
if [[ ! -f ~/.config/homelab-gitops/chengdu-k3s-token ]]; then
  umask 077
  openssl rand -hex 32 > ~/.config/homelab-gitops/chengdu-k3s-token
fi
export K3S_TOKEN="$(< ~/.config/homelab-gitops/chengdu-k3s-token)"
```

该文件是恢复集群所需的敏感凭据，应进入个人密码管理或加密备份；Token 轮换不属于本 Playbook 的职责。

检查语法、目标节点与 SSH 连接：

```bash
ansible-playbook playbooks/k3s.yml --syntax-check
ansible-playbook playbooks/k3s.yml --list-hosts
ansible k3s_servers -m ping
```

首次安装时执行：

```bash
ansible-playbook playbooks/k3s.yml
unset K3S_TOKEN
```

Playbook 会依次完成：

1. 通过 `ops` 用户配置三台 Debian 节点的 QEMU Guest Agent、NTP 时间同步、内核模块、sysctl 与基础软件。
2. 在 `cd-k3s-server-01` 初始化嵌入式 etcd。
3. 将另外两台 Server 加入集群。
4. 部署 kube-vip，以 ARP 模式提供 `10.10.10.69:6443`。
5. 将本地 Kubeconfig 写入 `~/.kube/homelab-chengdu.yaml`。

验证：

```bash
KUBECONFIG=~/.kube/homelab-chengdu.yaml kubectl get nodes -o wide
ping -c 2 10.10.10.69
```

版本升级必须先修改 `group_vars/all.yml`，审核差异后再执行 Playbook。
