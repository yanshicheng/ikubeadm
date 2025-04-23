# ikubeadm

![Kubernetes](https://img.shields.io/badge/Kubernetes-%E5%A4%9A%E9%9B%86%E7%BE%A4%E9%83%A8%E7%BD%B2-326CE5?style=flat-square&logo=kubernetes&logoColor=white)![Ansible](https://img.shields.io/badge/Ansible-%E8%87%AA%E5%8A%A8%E5%8C%96-EE0000?style=flat-square&logo=ansible&logoColor=white)![Container](https://img.shields.io/badge/%E5%AE%B9%E5%99%A8%E8%BF%90%E8%A1%8C%E6%97%B6-Docker%2FContainerd-2496ED?style=flat-square&logo=docker&logoColor=white)![Platform](https://img.shields.io/badge/平台-CentOS%20|%20Ubuntu%20|%20AlmaLinux%20|%20EulerOS-lightgrey?style=flat-square)![License](https://img.shields.io/badge/%E5%BC%80%E6%BA%90%E5%8D%8F%E8%AE%AE-Apache%202.0-blue?style=flat-square)

## 项目简介

ikubeadm 是一个企业级 Kubernetes 多集群自动化部署和管理解决方案，基于 Ansible 构建。提供了完整的部署流水线，支持从系统初始化到集群组件部署的全流程自动化，使集群管理员能够以可重复、一致的方式快速部署和管理多个 Kubernetes 集群。

无论是在本地环境、数据中心还是离线环境中，ikubeadm 都能提供灵活的部署选项和丰富的定制能力，满足企业级生产环境对 Kubernetes 的部署和管理需求。

⭐ 异构支持，支持多种操作系统，arm or amd 混合部署。

⭐ 每个 role 都简单写了 README 可以具体下看 `roles/role_name/README.md`

⭐ 具体了解可以查看: ` roles/role_name/default/main.yml`

> ⭐ "一次配置，随处部署，多集群统一管理"

### 核心特性与功能s

#### 管理特性

- **全生命周期管理**：从系统初始化到集群运维的完整覆盖
- **多集群管理**：支持在单一控制平面下管理多个异构 Kubernetes 集群

#### 部署选项

- 灵活部署模式

  - 控制平面支持静态 Pod 模式和二进制模式部署
- 集群组件支持 YAML 静态文件部署和 Helm 部署

#### 容器与网络

- 容器运行时支持

  - 完整支持 Docker 和 Containerd（推荐使用 Containerd）
- 自动配置运行时参数和优化
- 网络解决方案

  - 支持 Calico 网络插件
- 支持 BGP/IPIP/VXLAN 多种网络模式

#### 高可用与安全

- 高可用架构

  - 多控制平面节点设计
  - 内置 kube-vip 提供控制平面高可用
  - 支持外部自定义 lb 负载均衡器
- ETCD 集群灵活配置

  - 支持二进制部署和静态 Pod 部署
- 支持接入外部 ETCD 集群
- 安全加固

  - TLS 证书自动化管理
- 集群组件间安全通信

#### 异构支持

- 操作系统
  - 支持 Debian 系列
  - 支持 RedHat [ 'CentOS', 'RedHat', 'Rocky', 'AlmaLinux', 'EulerOS' ]
- CPU 架构
  - 支持 amd64
  - 支持 arm64

### 其他特性

- **离线部署支持**：内置镜像和软件包下载脚本，支持完全离线环境部署
- **丰富的组件集成**：开箱即用的核心组件和附加功能
- **功能级开关控制**：通过变量控制各组件功能的开启/关闭

### 技术架构

ikubeadm 基于 Ansible 自动化平台构建，采用模块化的 Roles 设计，使部署流程清晰可控。核心架构包括：

- **配置管理**：集中式配置，多集群差异化管理
- **部署流水线**：从系统初始化到组件部署的完整工作流
- **角色分离**：将各组件的安装配置封装为独立角色
- **脚本支持**：辅助脚本简化环境准备和资源管理

## 快速开始

### 前置条件

- 部署机器需要安装 Ansible (2.9+)
- 目标服务器为 Linux 系统  [ 'Debian,'CentOS', 'RedHat', 'Rocky', 'AlmaLinux', 'EulerOS' ]
- 容器运行时要求：
  - Docker 20.10+ 或
  - Containerd 1.6+（推荐）
- 硬件最低要求：
  - 控制平面节点：2 CPU，4GB 内存，50GB 存储
  - 工作节点：2 CPU，2GB 内存，50GB 存储

### 代码克隆

```bash
cd /opt/
git clone https://github.com/yanshicheng/ikubeadm.git
```

> ⚠️ **注意**：如果不在 opt 目录下，请手动修改 ansible.cfg 文件 roles_path 字段指定项目 roles 路径。

### 部署包准备

#### 镜像预下载

```bash
# 使用 Bash v4 脚本下载镜像
bash script/download-images-local-4.sh

# 使用 Bash v3 脚本下载镜像(适用于 macOS)
bash script/download-images-local-3.sh
```

> ⚠️ **镜像处理说明**：下载完镜像后，您有两种选择：
>
> 1. 打包 `registry data` 目录后在内网机器上部署 registry 仓库
> 2. 将镜像上传到您自己的 harbor 仓库
>
> 配置时需修改 `deploy/deploy_name/config.yaml` 中的 `registry` 和 `registry_ip` 参数。请注意保持正确的二级目录结构。

#### 软件包预下载

```bash
# 下载所需的软件包
bash script/download-packages-local.sh
```

> 📦 **软件包处理说明**：如果不是在 Ansible 控制主机上下载，只需将下载完成的软件包放入项目根目录下的 `packages` 目录即可。

#### 本地源配置

```bash
# 配置本地 YUM 和 Docker 源
bash script/deploy_local_repo.sh
```

> ⚠️ **注意**：本地源配置功能目前还未完善，请根据需求自行搭建 yum 或 apt 源。

### 集群部署流程

#### 1. 创建新的集群部署

```bash
# 在项目根目录下执行
❯ bash script/add-deploy-cluster.sh -n mycluster
正在创建新部署 'mycluster'...
正在更新配置文件...

部署 'mycluster' 已成功创建！

后续步骤:
1. 修改主配置文件: deploy/mycluster/config.yml
2. 配置主机相关信息: deploy/mycluster/hosts

准备好后，请从主目录执行以下命令开始部署:
ansible-playbook -e @deploy/mycluster/config.yml -i deploy/mycluster/hosts playbooks/00.deploy-kubernetes.yml
```

#### 2. 配置集群

1. 编辑主配置文件：`deploy/mycluster/config.yml`
2. 配置主机信息：`deploy/mycluster/hosts`

#### 3. 执行部署

```bash
# 在项目根目录下执行完整部署
ansible-playbook -e @deploy/mycluster/config.yml -i deploy/mycluster/hosts playbooks/00.deploy-kubernetes.yml

# 或分步执行
ansible-playbook -e @deploy/mycluster/config.yml -i deploy/mycluster/hosts playbooks/01.system-init.yml
ansible-playbook -e @deploy/mycluster/config.yml -i deploy/mycluster/hosts playbooks/02.chrony.yml
# ... 其他步骤
```

## 项目明细

### 目录结构

```
ikube-admin/
├── ansible.cfg                        # Ansible 配置文件
├── deploy                             # 部署配置目录
│   └── example                        # 示例部署配置
│       ├── config.yml                 # 集群配置文件
│       ├── hosts                      # 主机清单文件
│       └── registry                   # 镜像仓库证书目录
│           ├── harbor.ikubeops.local
│           │   └── ca.crt
│           └── registry1.example.com:5000
│               └── ca.crt
├── images                             # 内置镜像目录
├── logs                               # 部署日志目录
├── packages                           # 二进制软件包目录
├── playbooks                          # Ansible playbook 目录
│   ├── 00.deploy-kubernetes.yml       # 完整部署流程
│   ├── 01.system-init.yml             # 系统初始化
│   ├── 02.chrony.yml                  # 时间同步服务
│   ├── 03.container-runtime.yml       # 容器运行时
│   ├── 04.cert-manager.yml            # 证书管理
│   ├── 05.kube-node.yml               # 节点初始化
│   ├── 06.etcd.yml                    # ETCD 集群
│   ├── 07.kube-vip.yaml               # 控制平面高可用
│   ├── 08.kube-master.yml             # 控制平面组件
│   ├── 09.kube-dns.yaml               # DNS 服务
│   ├── 10.kube-cni.yml                # 网络插件
│   ├── 11.kube-addon.yaml             # 附加组件
│   └── 90.restart-system.yml          # 系统重启
├── roles                              # Ansible 角色目录
└── script                             # 辅助脚本目录
```

### 功能清单


| 功能模块   | 描述                         | 状态 |
| ---------- | ---------------------------- | ---- |
| 系统初始化 | 系统参数优化、依赖安装       | ✅   |
| 时间同步   | Chrony 服务部署与配置        | ✅   |
| 容器运行时 | Docker/Containerd 安装与配置 | ✅   |
| 证书管理   | TLS 证书生成与分发           | ✅   |
| 节点初始化 | Kubelet 服务配置与启动       | ✅   |
| ETCD 集群  | 高可用数据存储集群           | ✅   |
| 高可用配置 | Kube-VIP 虚拟 IP 管理        | ✅   |
| 控制平面   | API 服务器、控制器、调度器   | ✅   |
| DNS 服务   | CoreDNS 服务部署             | ✅   |
| 网络插件   | Calico CNI 部署              | ✅   |
| 存储服务   | NFS 存储提供程序             | ✅   |
| 负载均衡   | MetalLB 内部负载均衡器       | ✅   |
| 入口控制器 | Nginx Ingress Controller     | ✅   |
| 监控服务   | Metrics Server               | ✅   |

### 核心组件

#### 基础设施组件

- **系统初始化**：系统参数优化、网络配置、安全设置、必要软件包安装
- **时间同步**：Chrony 服务部署与配置
- **容器运行时**：Docker/Containerd 安装和配置、镜像仓库配置、安全和性能优化

#### Kubernetes 核心组件

- **证书管理**：CA 证书生成、组件证书分发、证书更新和轮换
- **ETCD 集群**：高可用 ETCD 部署、数据一致性保障、备份和恢复机制
- **Kubernetes 控制平面**：API 服务器、控制器管理器、调度器
- **节点组件**：Kubelet、Kube-proxy 配置与管理

#### 网络与插件组件

- **网络组件**：Calico CNI 插件、BGP/VXLAN/IPIP 网络模式、网络策略管理
- **DNS 服务**：CoreDNS 部署与配置
- **附加组件**：MetalLB 负载均衡器、NFS 存储提供程序、Metrics Server、Nginx Ingress Controller

## 配置指南

### 基础配置


| 参数                     | 说明             | 默认值                |
| ------------------------ | ---------------- | --------------------- |
| `deploy_name`            | 部署名称         | `example`             |
| `base_dir`               | 二进制安装路径   | `/opt/kube`           |
| `kube_base_dir`          | k8s 证书存储路径 | `/etc/kubernetes`     |
| `kubelet_base_dir`       | kubelet 数据目录 | `/var/lib/kubelet`    |
| `container_data_root`    | 容器数据路径     | `/var/lib/containerd` |
| `kubernetes_version`     | Kubernetes 版本  | `v1.32.3`             |
| `control_deploy_pattern` | 控制平面部署模式 | `manifest`            |
| `addon_deploy_pattern`   | 插件部署模式     | `yaml`                |
| `container_runtime`      | 容器运行时       | `containerd`          |
| `container_version`      | 容器运行时版本   | `2.0.4`               |

### 网络配置


| 参数                     | 说明                   | 默认值          |
| ------------------------ | ---------------------- | --------------- |
| `kube_apiserver_lb_addr` | API 服务器负载均衡地址 | `172.16.1.200`  |
| `kube_apiserver_lb_port` | API 服务器端口         | `6443`          |
| `service_cidr`           | 服务网络 CIDR          | `10.96.0.0/12`  |
| `pod_cidr`               | Pod 网络 CIDR          | `10.244.0.0/16` |
| `max_pods`               | 节点最大 Pod 数量      | `110`           |
| `service_nodeport_range` | Service NodePort 范围  | `30000-32767`   |
| `cluster_dns_domain`     | 集群 DNS 域名          | `cluster.local` |

### 证书配置


| 参数               | 说明             | 默认值 |
| ------------------ | ---------------- | ------ |
| `cert_update_mode` | 证书更新模式     | `none` |
| `ca_expiry`        | CA 证书有效期    | `20h`  |
| `cert_expiry`      | 组件证书有效期   | `20h`  |
| `custom_expiry`    | 自定义证书有效期 | `20h`  |

### 组件配置


| 参数                         | 说明                    | 默认值           |
| ---------------------------- | ----------------------- | ---------------- |
| `cluster_cni`                | 网络插件                | `calico`         |
| `cluster_cni_namespace`      | 网络插件命名空间        | `calico-system`  |
| `calico_mode`                | Calico 网络模式         | `vxlan`          |
| `use_external_etcd`          | 是否使用外部 ETCD       | `false`          |
| `etcd_deploy_mode`           | ETCD 部署模式           | `manifest`       |
| `etcd_data_dir`              | ETCD 数据目录           | `/var/lib/etcd`  |
| `metrics_server_enabled`     | 是否部署 Metrics Server | `true`           |
| `metallb_enabled`            | 是否部署 MetalLB        | `true`           |
| `metallb_namespace`          | MetalLB 命名空间        | `metallb-system` |
| `nfs_enabled`                | 是否部署 NFS 存储       | `true`           |
| `nfs_namespace`              | NFS 命名空间            | `nfs-system`     |
| `nginx_ingress_enabled`      | 是否部署 Ingress-Nginx  | `true`           |
| `nginx_ingress_namespace`    | Ingress-Nginx 命名空间  | `ingress-nginx`  |
| `nginx_ingress_service_type` | Ingress-Nginx 服务类型  | `ClusterIP`      |

## 高级功能

### 证书更新

```yaml
# 证书更新模式
# none: 不更新任何证书（默认值）
# ca_only: 只更新 CA 证书，不更新组件证书
# components_only: 只更新组件证书，不更新 CA 证书
# all: 更新所有证书
cert_update_mode: "none"

# 证书有效期设置
ca_expiry: "20h"      # CA 证书有效期
cert_expiry: "20h"    # 组件证书有效期
```

### 高可用控制平面

```yaml
# Kube-VIP 配置
kube_vip_deploy_mode: arp       # 部署模式 arp | bgp
kube_vip_interface: "eth2"      # 网络接口
kube_vip_version: "v0.8.9"      # Kube-VIP 版本
```

### 外部 ETCD 集群

```yaml
# 使用外部 ETCD 集群
use_external_etcd: true
external_etcd_endpoints: "https://etcd-1.example.com:2379,https://etcd-2.example.com:2379,https://etcd-3.example.com:2379"
```

## 最佳实践

1. 版本选择
   - 使用稳定版 Kubernetes
   - 避免使用预览版功能
2. 容器运行时
   - 优先使用 Containerd
   - 为容器数据配置单独存储
3. 高可用配置
   - 至少部署 3 个控制平面节点
   - 使用奇数个 ETCD 节点
4. 网络规划
   - 合理规划 Pod 和 Service CIDR
   - 避免与现有网络重叠
5. 资源配置
   - 为控制平面节点分配足够资源
   - 根据工作负载调整 max_pods 值

## 待更新事项

- [ ]  增加更多 CNI 插件选项（Cilium、Flannel）
- [ ]  集成 Kubernetes 升级功能
- [ ]  增加集群备份和恢复工具
- [ ]  helm 管理
- [ ]  集成更多监控和日志解决方案
- [ ]  所有初始化项目 golang 编写 ikubeadm-cli 工具
- [ ]  核心组件二进制部署
