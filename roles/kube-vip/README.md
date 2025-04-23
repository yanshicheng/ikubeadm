# Kube-VIP 角色

![高可用](https://img.shields.io/badge/%E9%AB%98%E5%8F%AF%E7%94%A8-Kube--VIP-blue)![负载均衡](https://img.shields.io/badge/%E8%B4%9F%E8%BD%BD%E5%9D%87%E8%A1%A1-VIP-orange)![Kubernetes](https://img.shields.io/badge/Kubernetes-%E6%8E%A7%E5%88%B6%E5%B9%B3%E9%9D%A2-green)

## 📋 简介

`kube-vip` 角色负责在 Kubernetes 集群中部署和配置 kube-vip 服务，为控制平面提供高可用性虚拟 IP 解决方案。kube-vip 是一个轻量级的工具，能够在不依赖外部负载均衡器的情况下，为 Kubernetes API 服务器提供虚拟 IP 地址，确保控制平面的高可用性和冗余性。

该角色支持两种主要的 VIP 实现方式：ARP（适用于单一二层网络）和 BGP（适用于跨网段环境），可以根据不同的网络环境灵活选择。同时，它还可以作为集群内部的服务负载均衡器，为集群内部服务提供类似云厂商负载均衡器的功能。

## 🎯 适用场景

* **自建 Kubernetes 集群的高可用性需求**：为没有云厂商提供的负载均衡器的环境提供高可用解决方案
* **边缘计算环境**：在资源受限的边缘节点上提供轻量级高可用方案
* **数据中心内部部署**：在企业内部数据中心环境中部署高可用 Kubernetes 集群
* **多控制平面节点架构**：确保多个控制平面节点间的负载均衡和高可用
* **裸金属服务器部署**：在没有内置负载均衡功能的裸金属环境中部署
* **混合云环境**：在混合云环境中统一高可用性解决方案
* **单一二层网络环境**：使用 ARP 模式提供简单高效的高可用性
* **跨网段/跨数据中心环境**：使用 BGP 模式在复杂网络拓扑中提供高可用性

## ✨ 功能说明

### 🔄 部署模式支持

* **ARP 模式**：
  * 基于 ARP 协议实现虚拟 IP 漂移
  * 适用于单一二层网络环境
  * 配置简单，无需额外网络设备支持
  * 使用选举机制确保只有一个节点响应 VIP 请求
* **BGP 模式**：
  * 基于边界网关协议实现路由通告
  * 适用于跨网段、跨数据中心环境
  * 支持与现有网络基础设施集成
  * 可配置 BGP 对等体和 AS 号

### ⚖️ 负载均衡功能

* **内部服务负载均衡**：为集群内部服务提供负载均衡功能
* **多种转发方法**：支持本地、隧道、伪装、直接路由和绕过等多种转发方式
* **与 IPVS 集成**：利用 Linux 内核的 IPVS 模块实现高效转发

### 🔍 监控与可观测性

* **Prometheus 集成**：提供 Prometheus 格式的监控指标
* **健康状态检查**：实时监控虚拟 IP 和服务的健康状态
* **日志输出**：详细的操作日志便于问题排查

### 🛠️ 自动化部署与配置

* **静态 Pod 部署**：作为 Kubernetes 静态 Pod 部署，不依赖于 API 服务器
* **配置文件生成**：自动生成所需的配置文件和清单
* **参数验证**：部署前验证配置参数的有效性

## 📝 变量说明

### 基础配置变量


| 变量名                   | 默认值                            | 说明                      |
| ------------------------ | --------------------------------- | ------------------------- |
| `kube_base_dir`          | `/etc/kubernetes`                 | Kubernetes 配置基础目录   |
| `base_dir`               | `/opt/kubernetes`                 | Kubernetes 二进制文件目录 |
| `container_runtime`      | `"containerd"`                    | 容器运行时类型            |
| `kube_vip_manifest_path` | `"{{ kube_base_dir }}/manifests"` | kube-vip 配置文件存放路径 |
| `kube_vip_deploy_mode`   | `"arp"`                           | 部署模式：`arp`或`bgp`    |

### 虚拟 IP 配置


| 变量名                   | 默认值        | 说明                            |
| ------------------------ | ------------- | ------------------------------- |
| `kube_apiserver_lb_addr` | `"127.0.0.1"` | 虚拟 IP 地址                    |
| `kube_apiserver_lb_port` | `"6443"`      | API 服务器端口                  |
| `kube_vip_cidr`          | `"32"`        | 虚拟 IP 的 CIDR 前缀长度        |
| `kube_vip_subnet`        | `"/32"`       | 虚拟 IP 的子网掩码（CIDR 格式） |

### 镜像配置


| 变量名             | 默认值                           | 说明                  |
| ------------------ | -------------------------------- | --------------------- |
| `registry`         | `"registry.ikubeops.local:5000"` | 容器镜像仓库地址      |
| `registry_project` | `"ikubeops"`                     | 镜像仓库项目名        |
| `kube_vip_version` | `"v0.8.9"`                       | kube-vip 版本         |
| `kube_vip_image`   | 自动生成                         | kube-vip 完整镜像地址 |

### ARP 模式配置


| 变量名               | 默认值   | 说明                   |
| -------------------- | -------- | ---------------------- |
| `kube_vip_interface` | `"eth0"` | ARP 模式使用的网络接口 |

### BGP 模式配置


| 变量名                     | 默认值    | 说明                                      |
| -------------------------- | --------- | ----------------------------------------- |
| `kube_vip_bgp_enable`      | `false`   | 是否启用 BGP 模式                         |
| `kube_vip_bgp_interface`   | `"lo"`    | BGP 模式使用的网络接口                    |
| `kube_vip_bgp_routerid`    | `""`      | BGP 路由器 ID（为空时使用节点 IP）        |
| `kube_vip_bgp_as`          | `"64513"` | 本地 AS 号                                |
| `kube_vip_bgp_peeraddress` | `""`      | BGP 对等体地址                            |
| `kube_vip_bgp_peerpass`    | `""`      | BGP 对等体密码                            |
| `kube_vip_bgp_peeras`      | `"64513"` | BGP 对等体 AS 号                          |
| `kube_vip_bgp_peers`       | `""`      | BGP 对等体列表（格式：IP:AS号:密码:多跳） |

### 高级功能配置


| 变量名                       | 默认值    | 说明                     |
| ---------------------------- | --------- | ------------------------ |
| `kube_vip_leader_election`   | `true`    | 是否启用领导者选举       |
| `kube_vip_enable_lb`         | `true`    | 是否启用负载均衡功能     |
| `kube_vip_lb_fwdmethod`      | `"local"` | 负载均衡转发方法         |
| `kube_vip_enable_prometheus` | `true`    | 是否启用 Prometheus 监控 |
| `kube_vip_prometheus`        | `":2112"` | Prometheus 指标暴露端口  |

## 🚀 使用方式

### 基本用法

1. 在 playbook 中引用角色:

```yaml
- hosts: kube_masters
  roles:
    - kube-vip
```

2. 自定义虚拟 IP 地址:

```yaml
- hosts: kube_masters
  vars:
    kube_apiserver_lb_addr: "192.168.1.100"
    kube_apiserver_lb_port: "6443"
  roles:
    - kube-vip
```

### ARP 模式配置

```yaml
- hosts: kube_masters
  vars:
    kube_vip_deploy_mode: "arp"
    kube_apiserver_lb_addr: "192.168.1.100"
    kube_vip_interface: "ens192"  # 指定您的网络接口
  roles:
    - kube-vip
```

### BGP 模式配置

```yaml
- hosts: kube_masters
  vars:
    kube_vip_deploy_mode: "bgp"
    kube_apiserver_lb_addr: "192.168.1.100"
    kube_vip_bgp_enable: true
    kube_vip_bgp_as: "65000"
    kube_vip_bgp_peers: "192.168.1.254:65001::false"  # 路由器 IP:AS:密码:多跳
  roles:
    - kube-vip
```

### 高级配置示例

```yaml
- hosts: kube_masters
  vars:
    kube_vip_deploy_mode: "arp"
    kube_apiserver_lb_addr: "192.168.1.100"
    kube_vip_interface: "ens192"
    kube_vip_enable_lb: true
    kube_vip_lb_fwdmethod: "masquerade"
    kube_vip_enable_prometheus: true
    kube_vip_prometheus: ":2112"
  roles:
    - kube-vip
```

### 部署后验证

部署完成后，可以通过以下步骤验证 kube-vip 是否正常工作:

1. 检查 kube-vip Pod 是否正常运行:
   ```bash
   kubectl -n kube-system get pod | grep kube-vip
   ```
2. 验证虚拟 IP 是否可访问:
   ```bash
   ping <kube_apiserver_lb_addr>
   ```
3. 验证 API 服务器端点:
   ```bash
   curl -k https://<kube_apiserver_lb_addr>:<kube_apiserver_lb_port>/healthz
   ```
4. 如果使用的是 BGP 模式，检查路由器上是否收到路由通告:
   ```bash
   # 在网络设备上执行
   show ip bgp neighbors
   show ip route bgp
   ```

### 注意事项

* **ARP 模式**:
  * 确保所有控制平面节点在同一个二层网络中
  * 确保网络环境允许 ARP 广播
  * 避免与网络中已有 IP 地址冲突
* **BGP 模式**:
  * 需要网络设备支持 BGP 协议
  * 配置正确的 AS 号和对等体信息
  * 可能需要网络管理员协助配置网络设备
* **负载均衡功能**:
  * 启用负载均衡功能时，确保已加载 IPVS 内核模块
  * 可以通过以下命令检查:
    ```bash
    lsmod | grep ip_vs
    ```
  * 如果未加载，请加载所需模块:
    ```bash
    modprobe ip_vsmodprobe ip_vs_rrmodprobe ip_vs_wrrmodprobe ip_vs_shmodprobe nf_conntrack
    ```
* **高可用配置**:
  * 建议至少部署 3 个控制平面节点以确保高可用性
  * 确保所有控制平面节点上的 kube-vip 配置一致

---

🔄 通过正确配置和部署 kube-vip，您可以为 Kubernetes 集群提供稳定可靠的高可用性控制平面，无需依赖外部负载均衡器服务。
