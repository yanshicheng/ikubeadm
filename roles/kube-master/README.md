# Kube-Master 角色

![Kubernetes](https://img.shields.io/badge/Kubernetes-%E6%8E%A7%E5%88%B6%E5%B9%B3%E9%9D%A2-blue)![Master](https://img.shields.io/badge/Master-%E9%83%A8%E7%BD%B2-orange)![高可用](https://img.shields.io/badge/%E9%AB%98%E5%8F%AF%E7%94%A8-%E9%9B%86%E7%BE%A4-green)

## 📋 简介

`kube-master` 角色负责在 Kubernetes 集群中部署和配置控制平面组件，是构建高可用 Kubernetes 集群的核心部分。该角色自动化了控制平面各组件（kube-apiserver、kube-controller-manager、kube-scheduler）的部署流程，并配置 kube-proxy 组件实现集群内部服务的网络代理。

角色支持以静态 Pod（manifest）或系统服务（systemd）两种模式部署控制平面组件，适应不同环境需求，同时内置完善的证书分发和健康检查机制，确保控制平面组件安全可靠地运行。

## 🎯 适用场景

* **新建 Kubernetes 集群**：快速部署标准 Kubernetes 控制平面
* **高可用控制平面构建**：部署多节点控制平面实现高可用性
* **控制平面升级**：在现有集群中升级控制平面组件版本
* **灾难恢复**：在控制平面故障后重建集群
* **自定义集群配置**：根据特定需求自定义控制平面参数
* **混合云环境**：在各种基础设施上部署标准化的控制平面
* **离线环境部署**：支持在无互联网环境中部署控制平面
* **大规模集群**：能够应对大型集群的控制平面配置需求

## ✨ 功能说明

### 🔐 证书与授权管理

* **证书分发**：将集群 CA 和组件证书分发到各节点
* **kubeconfig 配置**：为各组件生成专用的 kubeconfig 文件
* **证书完整性检查**：验证所有必需的证书和密钥是否已生成
* **角色绑定设置**：自动创建必要的 RBAC 权限

### 🏗️ 控制平面部署

* **多模式部署**：支持静态 Pod（manifest）和系统服务（systemd）部署模式
* **组件配置**：根据集群规模和需求自动配置控制平面组件参数
* **apiserver 高可用**：配置支持虚拟 IP 或负载均衡的高可用控制平面
* **etcd 集成**：支持使用内部或外部 etcd 集群
* **健康检查**：部署后自动验证各组件的健康状态

### 🌐 网络配置

* **kube-proxy 部署**：以 DaemonSet 方式部署 kube-proxy
* **IPVS 模式**：默认配置高性能的 IPVS 代理模式
* **服务网络**：自动配置集群服务网络和 DNS 服务

### 🏷️ 节点管理

* **节点标记**：自动为控制平面节点添加 control-plane 和 master 标签
* **污点设置**：为控制平面节点设置 NoSchedule 污点，防止工作负载干扰控制平面
* **工作节点标记**：为非控制平面节点添加 node 和 worker 标签

## 📝 变量说明

### 基础配置变量


| 变量名                   | 默认值                      | 说明                                                           |
| ------------------------ | --------------------------- | -------------------------------------------------------------- |
| `deploy_name`            | `"example"`                 | 部署名称，用于组织生成的文件                                   |
| `kubernetes_version`     | `"v1.32.3"`                 | Kubernetes 版本                                                |
| `control_deploy_pattern` | `"manifest"`                | 控制平面部署模式：`manifest`（静态Pod）或`systemd`（系统服务） |
| `kube_base_dir`          | `"/etc/kubernetes"`         | Kubernetes 配置基础目录                                        |
| `base_dir`               | `"/opt/kubernetes"`         | 二进制文件存放路径                                             |
| `ca_dir`                 | `"{{ kube_base_dir }}/pki"` | 证书存储目录                                                   |
| `bind_all_address`       | `"0.0.0.0"`                 | 组件监听地址（`0.0.0.0`或`127.0.0.1`）                         |

### 网络配置


| 变量名                   | 默认值            | 说明                                      |
| ------------------------ | ----------------- | ----------------------------------------- |
| `kube_apiserver_lb_addr` | `"127.0.0.1"`     | API 服务器负载均衡器地址                  |
| `kube_apiserver_lb_port` | `"6443"`          | API 服务器负载均衡器端口                  |
| `service_cidr`           | `"10.96.0.0/12"`  | 服务网络 CIDR                             |
| `pod_cidr`               | `"10.244.0.0/16"` | Pod 网络 CIDR                             |
| `cluster_dns_domain`     | `"cluster.local"` | 集群 DNS 域名                             |
| `cluster_dns_svc_ip`     | 自动计算          | 集群 DNS 服务 IP（从 service\_cidr 计算） |
| `service_nodeport_range` | `"30000-32767"`   | NodePort 服务端口范围                     |
| `proxy_mode`             | `"ipvs"`          | kube-proxy 代理模式                       |

### 镜像配置


| 变量名             | 默认值                           | 说明             |
| ------------------ | -------------------------------- | ---------------- |
| `registry`         | `"registry.ikubeops.local:5000"` | 容器镜像仓库地址 |
| `registry_project` | `"ikubeops"`                     | 镜像仓库项目名   |

### etcd 配置


| 变量名                    | 默认值   | 说明                                                          |
| ------------------------- | -------- | ------------------------------------------------------------- |
| `use_external_etcd`       | `false`  | 是否使用外部 etcd 集群                                        |
| `external_etcd_endpoints` | -        | 外部 etcd 集群端点（仅当 use\_external\_etcd 为 true 时使用） |
| `inner_etcd_endpoints`    | 自动生成 | 内部 etcd 集群端点（基于 etcd 主机组自动生成）                |

### API 服务器配置


| 变量名                               | 默认值                                                                  | 说明               |
| ------------------------------------ | ----------------------------------------------------------------------- | ------------------ |
| `apiserver_api_audiences`            | `"api,istio-ca"`                                                        | API 服务器受众     |
| `apiserver_authorization_mode`       | `"Node,RBAC"`                                                           | 授权模式           |
| `apiserver_enable_admission_plugins` | `"NodeRestriction,MutatingAdmissionWebhook,ValidatingAdmissionWebhook"` | 启用的准入控制插件 |

## 🚀 使用方式

### 基本用法

1. 在 Ansible 清单文件中定义 master 和 node 主机组：

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
- hosts: ikube_master:ikube_node
  roles:
    - kube-master
```

### 高可用控制平面配置

```yaml
- hosts: ikube_master:ikube_node
  vars:
    kube_apiserver_lb_addr: "192.168.1.100"  # VIP 或负载均衡器地址
    control_deploy_pattern: "manifest"
    apiserver_authorization_mode: "Node,RBAC,ABAC"
  roles:
    - kube-master
```

### 使用外部 etcd 集群

```yaml
- hosts: ikube_master:ikube_node
  vars:
    use_external_etcd: true
    external_etcd_endpoints: "https://etcd-1.example.com:2379,https://etcd-2.example.com:2379,https://etcd-3.example.com:2379"
  roles:
    - kube-master
```

### 自定义网络配置

```yaml
- hosts: ikube_master:ikube_node
  vars:
    service_cidr: "172.16.0.0/16"
    pod_cidr: "172.17.0.0/16"
    cluster_dns_domain: "cluster.mycompany.com"
    proxy_mode: "ipvs"
  roles:
    - kube-master
```

### 部署流程说明

1. **前置条件**：
   * 确保已通过 `cert-manager` 角色生成所有必需的证书
   * 确保已通过 `kube-node` 角色在所有节点上部署 kubelet
   * 如果使用内部 etcd，确保已通过 `etcd` 角色部署 etcd 集群
2. **完整部署顺序**：
   ```bash
   # 1. 系统初始化
   ansible-playbook -i inventory.ini system-init.yml

   # 2. 容器运行时安装
   ansible-playbook -i inventory.ini container-runtime.yml

   # 3. 证书生成
   ansible-playbook -i inventory.ini cert-manager.yml

   # 4. etcd 集群部署（使用内部 etcd 时）
   ansible-playbook -i inventory.ini etcd.yml

   # 5. 控制平面前的节点初始化
   ansible-playbook -i inventory.ini kube-node.yml

   # 6. 控制平面部署
   ansible-playbook -i inventory.ini kube-master.yml

   # 7. 网络插件部署
   ansible-playbook -i inventory.ini cni.yml
   ```

### 验证部署

部署完成后，可以通过以下步骤验证控制平面是否正常运行：

1. 检查控制平面 Pod 状态：
   ```bash
   kubectl get pods -n kube-system
   ```
2. 验证节点状态和角色：
   ```bash
   kubectl get nodes -o wide
   ```
3. 检查各组件健康状态：
   ```bash
   kubectl get componentstatuses
   ```
4. 查看 kube-proxy 状态：
   ```bash
   kubectl get daemonset -n kube-system kube-proxy
   ```

### 注意事项

* **证书依赖**：在执行此角色前，必须先通过 `cert-manager` 角色生成所有必需的证书
* **部署顺序**：确保按照推荐的部署顺序执行各个角色
* **高可用配置**：使用多个控制平面节点时，必须配置虚拟 IP 或负载均衡器
* **etcd 配置**：确保 etcd 集群已正确配置并可访问
* **网络配置**：确保 `service_cidr` 和 `pod_cidr` 不与现有网络重叠
* **资源需求**：控制平面节点建议至少 2 核 CPU 和 4GB 内存
* **防火墙规则**：确保控制平面组件所需的端口已开放（如 6443, 10250-10252 等）

### 故障排除

如果控制平面部署失败，可以进行以下检查：

1. 检查证书文件是否正确分发：
   ```bash
   ls -la /etc/kubernetes/pki/
   ```
2. 查看静态 Pod 的日志：
   ```bash
   crictl logs <container_id>
   ```
3. 检查 kubelet 日志：
   ```bash
   journalctl -u kubelet -f
   ```
4. 验证 API 服务器健康状态：
   ```bash
   curl -k https://127.0.0.1:6443/healthz
   ```

---

🔄 通过正确配置和部署 kube-master 角色，您将获得一个功能完整、安全可靠的 Kubernetes 控制平面，为后续的工作负载部署奠定坚实基础。
