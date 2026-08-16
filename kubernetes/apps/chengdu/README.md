# 成都局域网入口

Traefik 监听节点 IP `10.10.10.70`（80 / 443），并按域名转发：

- `https://vault.cd.zouzonghua.cn`
- `https://linkding.cd.zouzonghua.cn`
- `https://grafana.cd.zouzonghua.cn`

已配置 Let's Encrypt 泛域名权威证书 `*.cd.zouzonghua.cn`，支持局域网直接 HTTPS 安全访问。

验证：

```bash
kubectl -n kube-system get service traefik
kubectl get ingressroute -A
curl -Iv https://linkding.cd.zouzonghua.cn
```
