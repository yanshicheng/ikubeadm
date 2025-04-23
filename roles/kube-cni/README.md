# Kube-CNI 角色

![网络](https://img.shields.io/badge/%E7%BD%91%E7%BB%9C-CNI-blue)![Calico](https://img.shields.io/badge/Calico-%E7%BD%91%E7%BB%9C%E6%8F%92%E4%BB%B6-orange)![Kubernetes](https://img.shields.io/badge/Kubernetes-%E7%BD%91%E7%BB%9C-green)

## 📋 简介

`kube-cni` 角色负责在 Kubernetes 集群中部署和配置容器网络接口（CNI）插件，确保集群内 Pod 之间的网络通信。该角色主要支持 Calico 网络插件，提供了灵活的网络模式选择和配置选项，满足不同场景下的网络需求。

Calico 是一个高性能、可扩展的开源网络和网络安全解决方案，为容器、虚拟机和本地主机工作负载提供网络连接和安全防护。通过该角色，您可以轻松部署 Calico，并根据实际需求选择合适的网络模式（BGP、VxLAN 或 IPIP）。

## 🎯 适用场景

* **新建 Kubernetes 集群**：为新集群提供完整的网络解决方案
* **生产环境部署**：需要高性能、安全和可靠网络的生产环境
* **多区域/多数据中心集群**：需要跨区域路由的大型集群环境
* **微服务架构**：需要细粒度网络策略控制的微服务应用
* **网络迁移**：从其他 CNI 插件迁移到 Calico
* **BGP 网络集成**：需要与现有 BGP 网络基础设施集成的环境
* **网络隔离要求**：需要严格网络隔离和安全策略的多租户环境
* **高性能计算**：对网络性能有严格要求的工作负载

## ✨ 功能说明

### 🌐 网络模式支持

* **BGP 模式**：
  * 使用 BGP 协议在节点间直接路由数据包
  * 支持 Route Reflector 配置，优化大型集群中的路由通告
  * 允许自定义 AS 号配置与外部网络集成
* **VxLAN 模式**：
  * 使用 UDP 封装在 Layer 2 网络上建立 Layer 3 Overlay 网络
  * 适用于不支持 BGP 的环境
  * 自动解决虚拟化环境中的端口冲突问题
* **IPIP 模式**：
  * 使用 IP-in-IP 封装技术
  * 在不支持 BGP 的环境中提供更好的性能表现

### 🔧 部署与配置

* **YAML 清单部署**：使用 Kubernetes 原生清单文件部署组件
* **组件分步部署**：按照正确顺序部署各个 Calico 组件
* **二进制工具分发**：部署 calicoctl 命令行工具，便于管理 Calico 资源
* **自动状态检查**：部署后自动验证各组件状态

### 🔍 网络策略与安全

* **网络策略支持**：通过部署控制器组件支持 Kubernetes NetworkPolicy
* **完整 RBAC 支持**：配置所需的角色和权限
* **节点-节点安全通信**：保障集群内通信安全

### 🔄 BGP 高级配置

* **Route Reflector 模式**：支持在大型集群中优化 BGP 路由
* **自定义 BGP 对等体**：支持配置与外部路由器的 BGP 对等关系
* **AS 号配置**：自定义 BGP AS 号以匹配现有网络

## 📝 变量说明

### 基础配置变量


| 变量名                  | 默认值            | 说明                         |
| ----------------------- | ----------------- | ---------------------------- |
| `base_dir`              | `/opt/kubernetes` | Kubernetes 二进制文件目录    |
| `pod_cidr`              | `10.244.0.0/16`   | Pod 网络 CIDR                |
| `service_cidr`          | `10.96.0.0/12`    | 服务网络 CIDR                |
| `addon_deploy_pattern`  | `yaml`            | 部署模式，支持`yaml`或`helm` |
| `cluster_cni_namespace` | `calico-system`   | CNI 组件部署命名空间         |
| `block_size`            | `24`              | 每个节点的子网掩码大小       |

### Calico 配置变量


| 变量名             | 默认值    | 说明                                    |
| ------------------ | --------- | --------------------------------------- |
| `calico_version`   | `v3.29.3` | Calico 版本                             |
| `calico_interface` | `""`      | Calico 使用的网络接口（为空则自动检测） |
| `calico_mode`      | `bgp`     | 网络模式，可选`bgp`、`vxlan`或`ipip`    |
| `calico_bgp_rr`    | `true`    | 是否启用 BGP Route Reflector            |
| `calico_mtu`       | `0`       | MTU 值（0表示自动检测）                 |
| `calico_as_number` | `64512`   | BGP AS 号                               |

### 镜像配置变量


| 变量名                          | 默认值                    | 说明                  |
| ------------------------------- | ------------------------- | --------------------- |
| `registry`                      | `registry.ikubeops.local` | 容器镜像仓库地址      |
| `registry_project`              | `ikubeops`                | 镜像仓库项目名        |
| `calico_registry_project`       | `calico`                  | Calico 镜像项目名     |
| `calico_node_image`             | 自动生成                  | Calico Node 组件镜像  |
| `cni_image`                     | 自动生成                  | CNI 插件镜像          |
| `calico_typha_image`            | 自动生成                  | Calico Typha 组件镜像 |
| `calico_kube_controllers_image` | 自动生成                  | Calico 控制器镜像     |

## 🚀 使用方式

### 基本用法

1. 在 Ansible 清单文件中定义 Kubernetes 主机组：

```ini
[ikube_master]
master-1 ansible_host=192.168.1.101
master-2 ansible_host=192.168.1.102
master-3 ansible_host=192.168.1.103

[ikube_node]
node-1 ansible_host=192.168.1.111
node-2 ansible_host=192.168.1.112
```

2. 在 playbook 中引用角色：

```yaml
- hosts: ikube_master
  vars:
    cluster_cni_mode: "calico"
  roles:
    - kube-cni
```

### 使用 BGP 模式（默认）

```yaml
- hosts: ikube_master
  vars:
    cluster_cni_mode: "calico"
    calico_mode: "bgp"
    calico_as_number: "64512"
  roles:
    - kube-cni
```

### 使用 VxLAN 模式

在不支持 BGP 的环境中，可以使用 VxLAN 模式：

```yaml
- hosts: ikube_master
  vars:
    cluster_cni_mode: "calico"
    calico_mode: "vxlan"
  roles:
    - kube-cni
```

### 配置 BGP Route Reflector

对于大型集群，可以配置 BGP Route Reflector 优化路由通告：

1. 在清单文件中定义 Route Reflector 节点：

```ini
[calico_rr_group]
master-1
```

2. 在 playbook 中启用 Route Reflector：

```yaml
- hosts: ikube_master
  vars:
    cluster_cni_mode: "calico"
    calico_mode: "bgp"
    calico_bgp_rr: true
  roles:
    - kube-cni
```

### 自定义网络配置

```yaml
- hosts: ikube_master
  vars:
    cluster_cni_mode: "calico"
    pod_cidr: "172.16.0.0/16"
    block_size: "26"
    calico_mtu: "1500"
    calico_interface: "ens192"  # 指定网络接口
  roles:
    - kube-cni
```

### 高级 BGP 配置示例

```yaml
- hosts: ikube_master
  vars:
    cluster_cni_mode: "calico"
    calico_mode: "bgp"
    calico_as_number: "65001"
    calico_bgp_rr: true
  roles:
    - kube-cni
```

### 部署后验证

部署完成后，可以使用以下命令验证 Calico 是否正常运行：

```bash
# 检查所有 Calico Pod 状态
kubectl get pods -n calico-system

# 检查节点 BGP 状态（BGP 模式）
calicoctl node status

# 查看已建立的 BGP 对等关系
calicoctl get bgpPeer -o wide

# 验证网络连通性
kubectl run -it --rm ping --image=busybox -- ping <Pod IP>
```

### 注意事项

* **网络模式选择**：
  * BGP 模式性能最佳，但需要环境支持 BGP 协议
  * VxLAN 模式兼容性最好，适用于大多数环境
  * IPIP 模式是 BGP 与 VxLAN 的折中方案
* **节点标记**：
  * 如果使用 Route Reflector，确保相关节点已正确标记
  * 标记可通过 `calico_rr_group` 主机组自动处理
* **网络接口**：
  * 如果不指定 `calico_interface`，Calico 将自动选择默认接口
  * 在多网卡环境中，建议明确指定接口名称
* **MTU 设置**：
  * 不同的网络模式可能需要不同的 MTU 设置
  * VXLAN 和 IPIP 模式通常需要比标准 MTU 小 50-100 字节
* **防火墙配置**：
  * 确保节点间允许 Calico 所需的网络流量
  * BGP 模式需要允许 TCP 端口 179
  * VxLAN 模式默认使用 UDP 端口 4789（在虚拟化环境中会自动修改为 4799）

---

🔄 通过正确配置和部署 kube-cni 角色，您将获得一个高性能、安全可靠的 Kubernetes 网络解决方案，为集群提供坚实的网络基础。
