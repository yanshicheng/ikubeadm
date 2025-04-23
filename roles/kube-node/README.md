# Kube-Node 角色

![Kubernetes](https://img.shields.io/badge/Kubernetes-%E8%8A%82%E7%82%B9%E7%AE%A1%E7%90%86-blue)![Kubelet](https://img.shields.io/badge/Kubelet-%E6%9C%8D%E5%8A%A1%E9%85%8D%E7%BD%AE-orange)![Node](https://img.shields.io/badge/Node-%E9%83%A8%E7%BD%B2-green)

## 📋 简介

`kube-node` 角色负责在 Kubernetes 集群中配置和管理工作节点。该角色实现了 kubelet 服务的完整生命周期管理，包括证书分发、配置生成、服务启动和状态验证等。作为 Kubernetes 集群部署的核心环节，该角色确保每个节点正确配置并能够安全地加入集群，为容器化应用提供稳定的运行环境。

角色执行前会进行完整的前置检查，确保所有必要文件就绪，执行完成后会验证服务状态，确保节点正常运行并能够接收调度的工作负载。

## 🎯 适用场景

* **Kubernetes 集群初始部署**：初始化集群工作节点
* **集群扩容**：向现有集群添加新的工作节点
* **节点组件升级**：升级 kubelet 和相关组件版本
* **节点配置调优**：修改节点参数以优化性能
* **证书更新**：当节点证书需要更新时
* **灾难恢复**：在节点故障后恢复配置
* **多架构部署**：支持 x86\_64、ARM64 等多种硬件架构
* **离线环境部署**：适用于无法连接互联网的环境

## ✨ 功能说明

### 🔍 前置检查

* **二进制文件验证**：确保控制端的 kubelet 和 kubectl 二进制文件存在
* **证书文件检查**：验证所需的 CA 证书和节点证书是否就绪
* **kubeconfig 检查**：确认节点专用的 kubeconfig 文件已生成

### 📁 目录结构准备

* **创建系统目录**：自动创建 kubelet、kube-proxy 等组件所需的目录
* **CNI 目录配置**：设置容器网络接口所需的目录
* **证书存储**：准备安全存储 TLS 证书的目录结构

### 🔐 证书和配置分发

* **CA 证书分发**：将集群根证书部署到节点
* **节点证书分发**：将节点专用的 TLS 证书和密钥部署到指定位置
* **kubeconfig 分发**：将节点的身份认证配置文件复制到合适位置

### ⚙️ 服务配置和管理

* **kubelet 配置生成**：基于模板创建 kubelet 配置文件
* **systemd 服务单元**：创建和配置 kubelet 的 systemd 服务
* **服务启动和监控**：启动 kubelet 服务并验证其运行状态
* **开机自启动**：确保服务在系统重启后自动启动

### 🌐 网络和 DNS 配置

* **DNS 解析器配置**：设置 systemd-resolved 确保正确的 DNS 解析
* **环境变量设置**：配置必要的系统环境变量
* **命令行工具增强**：添加 kubectl 命令自动补全功能

## 📝 变量说明

### 基本配置变量


| 变量名              | 默认值                      | 说明                      |
| ------------------- | --------------------------- | ------------------------- |
| `kube_base_dir`     | `/etc/kubernetes`           | Kubernetes 配置基础目录   |
| `kubelet_base_dir`  | `/var/lib/kubelet`          | kubelet 组件工作目录      |
| `ca_dir`            | `"{{ kube_base_dir }}/pki"` | 证书存储目录              |
| `base_dir`          | `/opt/kubernetes`           | Kubernetes 二进制文件目录 |
| `container_runtime` | `"containerd"`              | 容器运行时类型            |

### API 服务器配置


| 变量名                   | 默认值        | 说明                   |
| ------------------------ | ------------- | ---------------------- |
| `kube_apiserver_lb_addr` | `"127.0.0.1"` | API 服务器负载均衡地址 |
| `port_apiserver_port`    | `"6443"`      | API 服务器端口         |

### Kubelet 配置


| 变量名          | 默认值      | 说明                                     |
| --------------- | ----------- | ---------------------------------------- |
| `max_pods`      | `110`       | 节点最大 Pod 数量                        |
| `cgroup_driver` | `"systemd"` | cgroup 驱动类型                          |
| `pod_max_pids`  | `-1`        | 单个 Pod 允许的最大进程数 (-1表示不限制) |

### 网络配置


| 变量名                   | 默认值            | 说明                              |
| ------------------------ | ----------------- | --------------------------------- |
| `service_cidr`           | `"10.96.0.0/12"`  | 服务网络 CIDR                     |
| `cluster_dns_domain`     | `"cluster.local"` | 集群 DNS 域名后缀                 |
| `cluster_dns_svc_ip`     | 动态计算          | 集群 DNS 服务 IP (网段第10个地址) |
| `enable_local_dns_cache` | `true`            | 是否启用本地 DNS 缓存             |
| `local_dns_cache`        | `"169.254.20.10"` | 本地 DNS 缓存地址                 |

### 资源预留配置


| 变量名                  | 默认值 | 说明                             |
| ----------------------- | ------ | -------------------------------- |
| `kube_reserved_enabled` | `"no"` | 是否启用 Kubernetes 组件资源预留 |
| `sys_reserved_enabled`  | `"no"` | 是否启用系统资源预留             |

## 🚀 使用方式

### 基本用法

1. 在 ansible 清单文件中定义节点组：

```ini
[ikube_cluster]
node1 ansible_host=192.168.1.101
node2 ansible_host=192.168.1.102
node3 ansible_host=192.168.1.103
```

2. 在 playbook 中引用角色：

```yaml
- hosts: ikube_cluster
  roles:
    - kube-node
```

### 自定义节点配置

```yaml
- hosts: ikube_cluster
  vars:
    max_pods: 150
    cgroup_driver: "systemd"
    kube_reserved_enabled: "yes"
    kubernetes_version: "v1.32.3"
  roles:
    - kube-node
```

### 使用标签进行特定操作

```bash
# 仅升级 kubelet 组件及配置
ansible-playbook -i inventory.ini kube-node.yml --tags "upgrade_k8s,restart_node"

# 重启节点上的 kubelet 服务
ansible-playbook -i inventory.ini kube-node.yml --tags "restart_node"
```

### 节点添加流程

1. 首先确保证书已生成：

```bash
ansible-playbook -i inventory.ini cert-manager.yml
```

2. 然后部署节点组件：

```bash
ansible-playbook -i inventory.ini kube-node.yml
```

3. 验证节点状态：

```bash
kubectl get nodes
```

### 高级配置示例

1. 调整节点资源预留：

```yaml
vars:
  kube_reserved_enabled: "yes"
  sys_reserved_enabled: "yes"
```

2. 配置本地 DNS 缓存：

```yaml
vars:
  enable_local_dns_cache: true
  local_dns_cache: "169.254.20.10"
```

3. 自定义节点网络设置：

```yaml
vars:
  service_cidr: "10.244.0.0/16"
  cluster_dns_domain: "my-cluster.local"
```

### 注意事项

* 确保在执行角色前已通过 `cert-manager` 角色生成节点证书
* 每个节点的主机名需要唯一且符合 Kubernetes 命名规范
* 节点需要有足够的资源来运行系统组件和工作负载
* 节点间网络需要互通，特别是与控制平面的连接
* 如果修改 `service_cidr`，确保与控制平面配置一致
* 完成节点部署后，可能需要通过 `kubectl` 批准 CSR 请求

### 排障指南

如果节点部署后无法正常加入集群，请检查：

1. 证书是否正确分发：

```bash
ls -la /etc/kubernetes/pki/
```

2. kubelet 服务状态：

```bash
systemctl status kubelet
journalctl -u kubelet -n 100
```

3. 网络连接是否正常：

```bash
ping <kube_apiserver_lb_addr>
telnet <kube_apiserver_lb_addr> <port_apiserver_port>
```

4. API 服务器是否接受节点注册：

```bash
kubectl get csr
```

---

🔄 此角色是 Kubernetes 集群部署的核心组件，确保按照文档指导正确配置以构建稳定的集群环境。
