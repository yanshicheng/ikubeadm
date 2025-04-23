# Kube-Addon 角色

![插件](https://img.shields.io/badge/Kubernetes-%E6%8F%92%E4%BB%B6-blue)![增强](https://img.shields.io/badge/%E9%9B%86%E7%BE%A4-%E5%A2%9E%E5%BC%BA%E5%8A%9F%E8%83%BD-orange)![生产就绪](https://img.shields.io/badge/%E7%94%9F%E4%BA%A7-%E5%B0%B1%E7%BB%AA-green)

## 📋 简介

`kube-addon` 角色负责在 Kubernetes 集群上部署和管理常用的增强组件，为基础集群添加监控、负载均衡、存储和流量管理等核心功能。该角色包含多个重要组件，使基础的 Kubernetes 集群转变为全功能的生产级平台。

角色采用模块化设计，允许选择性地启用或禁用各个组件，每个组件都可以通过变量进行细粒度配置。通过统一的部署方式和配置管理，确保集群附加组件的一致性和可靠性。

## 🎯 适用场景

* **生产环境集群增强**：为生产级 Kubernetes 集群添加必要的支持组件
* **内部云平台构建**：搭建类似公有云的完整功能集
* **裸金属环境部署**：为没有云厂商负载均衡器的环境提供替代方案
* **集群监控能力建设**：添加资源监控能力
* **多租户环境**：通过 Ingress Controller 实现多租户流量隔离
* **持久化存储需求**：为应用提供 NFS 持久化存储能力
* **DevOps 环境构建**：为 CI/CD 和应用部署提供必要的基础设施
* **边缘计算场景**：为边缘环境提供轻量级服务暴露能力

## ✨ 功能说明

### 📊 Metrics-Server

* **资源监控**：收集并提供节点和容器的 CPU 与内存使用数据
* **HPA 支持**：为 Kubernetes 水平 Pod 自动扩缩容提供指标支持
* **多副本部署**：支持高可用部署模式
* **定制化配置**：可根据集群规模调整资源配置

### 🔄 MetalLB

* **裸金属负载均衡**：为非云环境提供 LoadBalancer 类型服务实现
* **L2 模式**：支持二层网络 ARP/NDP 模式
* **IP 地址池管理**：灵活配置可用 IP 地址范围
* **BGP 模式支持**：通过 FRR 实现 BGP 路由通告
* **高可用架构**：控制器和 Speaker 组件冗余部署

### 💾 NFS Provider

* **CSI 驱动实现**：遵循容器存储接口标准
* **持久卷支持**：提供 NFS 类型的 PersistentVolume
* **动态存储供应**：通过 StorageClass 实现存储自动分配
* **卷快照功能**：支持持久卷数据备份（可选）
* **自定义挂载选项**：灵活配置 NFS 挂载参数

### 🌐 Nginx Ingress Controller

* **HTTP/HTTPS 流量路由**：基于主机和路径的请求转发
* **外部访问管理**：统一管理集群服务的外部访问
* **TLS 终结**：支持证书管理和 HTTPS 连接
* **高可用部署**：支持多副本控制器部署
* **灵活服务类型**：支持 LoadBalancer、NodePort 或 ClusterIP 模式

## 📝 变量说明

### 通用配置


| 变量名                 | 默认值                      | 说明                                              |
| ---------------------- | --------------------------- | ------------------------------------------------- |
| `kube_base_dir`        | `/etc/kubernetes`           | Kubernetes 配置基础目录                           |
| `base_dir`             | `/opt/kubernetes`           | Kubernetes 二进制文件目录                         |
| `addon_deploy_pattern` | `"manifests"`               | 部署方式：目前支持`manifests`，未来可能支持`helm` |
| `registry`             | `"registry.ikubeops.local"` | 镜像仓库地址                                      |
| `registry_project`     | `"ikubeops"`                | 镜像仓库项目名                                    |

### Metrics-Server 配置


| 变量名                     | 默认值          | 说明                    |
| -------------------------- | --------------- | ----------------------- |
| `metrics_server_enabled`   | `true`          | 是否启用 Metrics Server |
| `metrics_server_namespace` | `"kube-system"` | 部署的命名空间          |
| `metrics_server_replicas`  | `"2"`           | Pod 副本数量            |
| `metrics_server_version`   | `"v0.7.2"`      | Metrics Server 版本     |
| `metrics_server_image`     | 自动生成        | 完整镜像地址            |

### MetalLB 配置


| 变量名                               | 默认值                              | 说明             |
| ------------------------------------ | ----------------------------------- | ---------------- |
| `metallb_enabled`                    | `true`                              | 是否启用 MetalLB |
| `metallb_namespace`                  | `"metallb-system"`                  | 部署的命名空间   |
| `metallb_address_pool`               | `["172.16.1.40-45", "172.16.1.55"]` | IP 地址池配置    |
| `metallb_frr_controller_replicas`    | `2`                                 | FRR 控制器副本数 |
| `metallb_native_controller_replicas` | `2`                                 | 原生控制器副本数 |
| `metallb_speaker_version`            | `"v0.14.9"`                         | Speaker 组件版本 |
| `metallb_controller_version`         | `"v0.14.9"`                         | 控制器组件版本   |

### NFS Provider 配置


| 变量名                            | 默认值              | 说明                             |
| --------------------------------- | ------------------- | -------------------------------- |
| `nfs_enabled`                     | `true`              | 是否启用 NFS Provider            |
| `nfs_snapshot_controller_enabled` | `true`              | 是否启用快照控制器               |
| `nfs_namespace`                   | `"kube-system"`     | 部署的命名空间                   |
| `nfs_server`                      | `"172.16.1.111"`    | NFS 服务器地址                   |
| `nfs_share_path`                  | `"/nfs/k8s"`        | NFS 共享路径                     |
| `nfs_storeage_class_name`         | `"nfs-csi-default"` | StorageClass 名称                |
| `nfs_storeage_reclaim_policy`     | `"Retain"`          | 回收策略 (Retain/Delete/Archive) |
| `nfs_storeage_mount_options`      | `"fsvers=4.1,hard"` | NFS 挂载选项                     |
| `nfs_controller_replicas`         | `2`                 | 控制器副本数量                   |

### Nginx Ingress 配置


| 变量名                              | 默认值            | 说明                                       |
| ----------------------------------- | ----------------- | ------------------------------------------ |
| `nginx_ingress_enabled`             | `true`            | 是否启用 Nginx Ingress                     |
| `nginx_ingress_namespace`           | `"ingress-nginx"` | 部署的命名空间                             |
| `nginx_ingress_service_type`        | `"LoadBalancer"`  | 服务类型 (LoadBalancer/ClusterIP/NodePort) |
| `nginx_ingress_controller_replicas` | `2`               | 控制器副本数量                             |
| `nginx_ingress_controller_version`  | `"v1.12.1"`       | 控制器版本                                 |
| `nginx_ingress_controller_image`    | 自动生成          | 完整镜像地址                               |

## 🚀 使用方式

### 基本用法

1. 在 playbook 中引用角色：

```yaml
- hosts: ikube_master
  roles:
    - kube-addon
```

2. 自定义组件启用状态：

```yaml
- hosts: ikube_master
  vars:
    metrics_server_enabled: true
    metallb_enabled: true
    nfs_enabled: true
    nginx_ingress_enabled: true
  roles:
    - kube-addon
```

### 组件单独部署

使用标签可以选择性地部署特定组件：

```bash
# 仅部署 Metrics Server
ansible-playbook -i inventory.ini addon-playbook.yml --tags metrics-server

# 仅部署 MetalLB 和 Nginx Ingress
ansible-playbook -i inventory.ini addon-playbook.yml --tags "metallb,nginx-ingress"
```

### MetalLB 配置示例

配置自定义 IP 地址池：

```yaml
vars:
  metallb_address_pool:
    - 192.168.1.100-192.168.1.120
    - 192.168.1.150
```

### NFS 存储配置示例

配置 NFS 服务器和存储类：

```yaml
vars:
  nfs_server: "nfs.example.com"
  nfs_share_path: "/exports/kubernetes"
  nfs_storeage_class_name: "nfs-production"
  nfs_storeage_reclaim_policy: "Delete"
```

### Nginx Ingress 配置示例

配置为 NodePort 模式：

```yaml
vars:
  nginx_ingress_service_type: "NodePort"
  nginx_ingress_controller_replicas: 3
```

### 部署后验证

部署完成后，可以使用以下命令验证各组件状态：

```bash
# 检查 Metrics Server
kubectl top nodes
kubectl get pods -n kube-system -l k8s-app=metrics-server

# 检查 MetalLB
kubectl get pods -n metallb-system
kubectl get ipaddresspools -n metallb-system

# 测试 LoadBalancer 服务
kubectl create deploy nginx --image=nginx
kubectl expose deploy nginx --port=80 --type=LoadBalancer

# 检查 NFS Provider
kubectl get pods -n kube-system -l app=csi-nfs-controller
kubectl get sc

# 测试创建持久卷
kubectl create -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc-test
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Gi
  storageClassName: nfs-csi-default
EOF

# 检查 Nginx Ingress
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx
```

### 最佳实践

1. **组件顺序**：建议先部署 MetalLB，然后再部署需要 LoadBalancer 的 Nginx Ingress
2. **资源需求**：确保集群有足够的资源运行这些附加组件
3. **镜像仓库**：使用私有镜像仓库以提高部署速度和可靠性
4. **高可用性**：保持默认的副本数（2）以确保组件的高可用性
5. **存储备份**：如启用 NFS 快照控制器，定期创建卷快照
6. **访问控制**：部署后检查各组件的安全设置，特别是 Ingress Controller

### 注意事项

* **MetalLB 防火墙**：确保节点间允许 MetalLB 所需的流量
* **NFS 依赖**：确保 NFS 服务器可从所有节点访问且共享目录已正确配置
* **Ingress 配置**：使用 LoadBalancer 类型需要 MetalLB 或云提供商支持
* **资源限制**：在资源有限的环境中可考虑减少副本数量
* **版本兼容性**：确保组件版本与 Kubernetes 版本兼容

---

🔄 通过正确配置和部署这些核心插件，您的 Kubernetes 集群将具备生产级别的监控、负载均衡、存储和流量管理能力，为应用部署提供完善的基础设施支持。
