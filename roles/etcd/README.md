# ETCD 角色

![ETCD](https://img.shields.io/badge/ETCD-%E6%95%B0%E6%8D%AE%E5%BA%93-blue)![Kubernetes](https://img.shields.io/badge/Kubernetes-%E6%A0%B8%E5%BF%83%E7%BB%84%E4%BB%B6-orange)![高可用](https://img.shields.io/badge/%E9%AB%98%E5%8F%AF%E7%94%A8-%E9%9B%86%E7%BE%A4-green)

## 📋 简介

`etcd` 角色负责部署和管理 Kubernetes 集群的核心组件 - etcd 分布式键值存储数据库。etcd 是 Kubernetes 的"大脑"，用于存储集群的所有状态信息和配置数据。该角色实现了 etcd 集群的自动化部署、证书管理以及集群状态验证，确保部署的 etcd 集群高可用、安全且可靠。

本角色支持以静态 Pod（manifest）方式部署 etcd，使其作为 Kubernetes 控制平面的一部分运行，同时保持与 Kubernetes 组件的完整集成。

## 🎯 适用场景

* **新建 Kubernetes 集群**：初始部署 Kubernetes 集群时的 etcd 组件安装
* **高可用集群构建**：需要构建多节点 etcd 集群以提供高可用性
* **集群扩展**：向现有 etcd 集群添加新成员
* **证书更新**：需要为 etcd 集群更新 TLS 证书
* **版本升级**：升级 etcd 集群到新版本
* **生产环境部署**：需要安全、可靠的数据存储基础设施
* **离线环境部署**：支持在无互联网连接的环境中部署

## ✨ 功能说明

### 🔐 安全与证书管理

* **TLS 证书生成**：自动生成 etcd 所需的 TLS 证书和密钥
* **证书分发**：将证书安全地分发到所有 etcd 节点
* **基于 CA 的认证**：使用集群 CA 签发的证书确保通信安全

### 🏗️ 部署与配置

* **静态 Pod 部署**：以 Kubernetes 静态 Pod 方式部署 etcd（manifest 模式）
* **集群配置生成**：根据节点信息自动生成 etcd 初始集群配置
* **数据目录管理**：创建并配置 etcd 数据存储目录

### 🔄 集群管理

* **集群状态验证**：部署后自动检查 etcd 集群的健康状态
* **成员列表检查**：验证所有节点是否正确加入集群
* **端口可访问性测试**：确保 etcd 客户端和集群通信端口正常工作

### 📊 监控与状态报告

* **启动状态监控**：等待 etcd 容器正常启动并运行
* **集群状态报告**：提供集群成员状态的详细信息
* **端口可用性验证**：确保 etcd 服务端口可正常访问

## 📝 变量说明

### 基本配置变量


| 变量名             | 默认值                      | 说明                                      |
| ------------------ | --------------------------- | ----------------------------------------- |
| `etcd_deploy_mode` | `"manifest"`                | etcd 部署模式，支持`manifest`（静态 Pod） |
| `etcd_data_dir`    | `/var/lib/etcd`             | etcd 数据存储目录                         |
| `etcd_version`     | `"3.5.16-0"`                | etcd 容器镜像版本                         |
| `kube_base_dir`    | `/etc/kubernetes`           | Kubernetes 配置基础目录                   |
| `ca_dir`           | `"{{ kube_base_dir }}/pki"` | 证书存储目录                              |

### 镜像与容器配置


| 变量名              | 默认值                      | 说明                         |
| ------------------- | --------------------------- | ---------------------------- |
| `registry`          | `"registry.ikubeops.local"` | 容器镜像仓库地址             |
| `registry_project`  | `"ikubeops"`                | 镜像仓库项目名称             |
| `etcd_image`        | 自动生成                    | etcd 容器镜像完整路径        |
| `container_runtime` | `"containerd"`              | 容器运行时类型，影响检查命令 |

### 集群配置变量


| 变量名                 | 默认值      | 说明                             |
| ---------------------- | ----------- | -------------------------------- |
| `etcd_initial_cluster` | 动态生成    | 初始集群配置，从主机清单自动生成 |
| `deploy_name`          | `"example"` | 部署名称，用于组织生成的文件     |

### 证书相关变量


| 变量名               | 默认值    | 说明               |
| -------------------- | --------- | ------------------ |
| `generate_certs_dir` | 自动生成  | 证书生成目录路径   |
| `cfssl_version`      | `"1.6.5"` | CFSSL 工具版本     |
| `cfssl_dir`          | 自动生成  | CFSSL 工具目录路径 |

## 🚀 使用方式

### 基本用法

1. 在您的 Ansible 清单文件中定义 `etcd` 主机组：

```ini
[etcd]
master-1 ansible_host=192.168.1.101
master-2 ansible_host=192.168.1.102
master-3 ansible_host=192.168.1.103
```

2. 在 playbook 中引用角色：

```yaml
- hosts: etcd
  roles:
    - etcd
```

### 自定义配置示例

```yaml
- hosts: etcd
  vars:
    etcd_version: "3.5.16-0"
    etcd_data_dir: "/opt/etcd/data"
    registry: "my-registry.example.com"
    registry_project: "kubernetes"
    container_runtime: "docker"  # 如果使用 Docker 而非 Containerd
  roles:
    - etcd
```

### 高可用部署示例

```yaml
# 部署具有3个节点的高可用 etcd 集群
- hosts: etcd
  vars:
    deploy_name: "production-cluster"
    kube_base_dir: "/etc/kubernetes"
    etcd_data_dir: "/var/lib/etcd-data"  # 自定义数据目录
  roles:
    - etcd
```

### 使用标签选择性执行任务

```bash
# 只运行证书相关任务
ansible-playbook -i inventory.ini main.yml --tags "certs"

# 只验证 etcd 集群状态
ansible-playbook -i inventory.ini main.yml --tags "verify"
```

### 注意事项

* etcd 集群应由奇数个节点组成（通常为 1、3、5 或 7 个节点）
* 为确保集群稳定性，建议至少部署 3 个节点的集群
* etcd 对磁盘 I/O 性能敏感，建议使用 SSD 存储
* 默认情况下，etcd 监听以下端口：
  * 2379：客户端通信端口
  * 2380：集群节点通信端口
* 确保节点间网络延迟低且稳定
* 定期备份 etcd 数据

### 验证部署

部署完成后，可以使用以下命令验证 etcd 集群状态：

```bash
# 通过 etcdctl 验证集群状态
export ETCDCTL_API=3
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/ca.pem \
  --cert=/etc/kubernetes/pki/etcd.pem \
  --key=/etc/kubernetes/pki/etcd-key.pem \
  member list -w table

# 检查集群健康状态
etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/ca.pem \
  --cert=/etc/kubernetes/pki/etcd.pem \
  --key=/etc/kubernetes/pki/etcd-key.pem \
  endpoint health --cluster
```

---

🔄 更多详细信息，请参考 etcd 官方文档：[etcd.io](https://etcd.io/)
