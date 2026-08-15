# 成都局域网入口

Traefik 通过 kube-vip 使用 `10.10.10.68`，并按域名转发：

- `https://argocd.cd.home.arpa`
- `https://headlamp.cd.home.arpa`
- `https://grafana.cd.home.arpa`
- `https://nginx.cd.home.arpa`

当前使用 Traefik 默认自签证书，浏览器会提示证书不受信任；Argo CD CLI 继续使用本地端口转发。

验证：

```bash
kubectl -n kube-system get service traefik
kubectl get ingressroute -A
curl -kI https://headlamp.cd.home.arpa
```

Traefik 未获得 `10.10.10.68` 时，先检查：

```bash
kubectl -n kube-system logs daemonset/kube-vip-ds --tail=100
kubectl -n kube-system get helmchartconfig traefik -o yaml
```
