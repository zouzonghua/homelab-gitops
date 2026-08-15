# Secrets

本目录只允许提交 SOPS 加密文件（如 `*.sops.yaml`）。

严禁提交：

- WireGuard 或 age 私钥
- API Token、密码和 Kubeconfig
- 未加密的 OPNsense/PVE 配置备份
- OpenTofu State

SOPS 与 age 的密钥策略将在首次引入真实 Secret 前单独设计。
