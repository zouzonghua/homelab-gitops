# K8up 备份组件

K8up 是专为 Kubernetes 原生设计的轻量级备份 Operator（底层基于 Restic），通过 CRD 声明式管理 PVC 数据的自动增量备份、校验与清理。

---

## 🚀 快速使用（以备份 local-path PVC 到 NFS 为例）

### 1. 创建备份密码 Secret（加密 Restic 仓库）
```bash
kubectl create secret generic k8up-repo-secret \
  -n <namespace> \
  --from-literal=password='your-secure-password'
```

### 2. 创建 NFS 备份目标 PVC
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: k8up-nfs-backup
  namespace: <namespace>
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-client
  resources:
    requests:
      storage: 20Gi
```

### 3. 配置定时备份 Schedule
```yaml
apiVersion: k8up.io/v1
kind: Schedule
metadata:
  name: schedule-backup
  namespace: <namespace>
spec:
  backend:
    repoPasswordSecretRef:
      name: k8up-repo-secret
      key: password
    local:
      mountPath: /backups
  backup:
    schedule: "0 3 * * *" # 每天凌晨 3 点全自动增量备份
  check:
    schedule: "0 4 * * 0" # 每周日凌晨 4 点校验完整性
  prune:
    schedule: "0 5 * * 0" # 每周日凌晨 5 点清理过期快照
    retention:
      keepLast: 5
      keepDaily: 7
      keepWeekly: 4
  volumes:
    - name: backup-storage
      persistentVolumeClaim:
        claimName: k8up-nfs-backup
  volumeMounts:
    - name: backup-storage
      mountPath: /backups
```

*(可选)* 默认会对 Namespace 下的所有 PVC 进行备份。如需精确排除某个 PVC，在对应 PVC 上添加注解：`k8up.io/backup: "false"`。
