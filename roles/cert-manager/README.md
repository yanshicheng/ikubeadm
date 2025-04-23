# Kubernetes 证书生成器角色 (cert-generator)

# Cert-Manager 角色

![证书管理](https://img.shields.io/badge/%E8%AF%81%E4%B9%A6%E7%AE%A1%E7%90%86-Cert--Manager-blue)![Kubernetes](https://img.shields.io/badge/Kubernetes-%E8%AF%81%E4%B9%A6-orange)![CFSSL](https://img.shields.io/badge/CFSSL-TLS-green)

## 📋 简介

`cert-manager` 角色负责为 Kubernetes 集群生成和管理 TLS 证书，这些证书对于确保集群组件之间的安全通信至关重要。该角色使用 CFSSL（CloudFlare 的 SSL 工具包）作为证书生成工具，自动化创建所有必要的证书和 kubeconfig 配置文件，以建立 Kubernetes 集群所需的 PKI（公钥基础设施）。

通过这个角色，您可以轻松管理证书的生命周期，包括初始创建、更新和轮换，确保您的 Kubernetes 集群始终使用有效的、安全的 TLS 证书。

## 🎯 适用场景

* **初始 Kubernetes 集群部署**：为新集群设置完整的 PKI 基础设施
* **证书更新**：在证书接近过期时进行更新
* **灾难恢复**：在证书丢失或损坏后重新生成证书
* **集群扩展**：为新添加的节点生成所需的证书
* **Kubernetes 版本升级**：在升级过程中可能需要更新证书
* **安全策略强化**：更新证书配置以符合最新的安全标准
* **集群维护**：定期轮换证书作为安全最佳实践

## ✨ 功能说明

### 🔐 证书生成功能

* **根证书颁发机构 (CA)**：创建自签名 CA 证书，用于签署所有其他证书
* **API 服务器证书**：为 kube-apiserver 生成服务器证书
* **客户端证书**：为各个 Kubernetes 组件生成客户端认证证书，包括：
  * admin 用户证书
  * kube-controller-manager 证书
  * kube-scheduler 证书
  * kube-proxy 证书
  * kubelet 节点证书（为集群中每个节点单独生成）
  * aggregator-proxy 证书（用于 API 聚合）

### 📄 配置文件生成

* **kubeconfig 文件**：为各组件自动生成 kubeconfig 配置文件，包括：
  * admin.kubeconfig
  * kube-controller-manager.kubeconfig
  * kube-scheduler.kubeconfig
  * kube-proxy.kubeconfig
  * 各节点的 kubelet.kubeconfig

### 🔄 证书生命周期管理

* **证书更新模式**：支持多种更新策略
  * 仅更新 CA 证书
  * 仅更新组件证书
  * 更新所有证书
  * 不更新任何证书（默认）
* **证书备份**：更新前自动备份现有证书和配置
* **证书有效期设置**：可自定义 CA 和组件证书的有效期

### 🛠️ 系统准备和验证

* **工具检查**：验证必要工具（cfssl、cfssljson、kubectl）是否已安装
* **目录准备**：自动创建所需的目录结构
* **完成验证**：生成过程完成后提供状态报告

## 📝 变量说明

### 基础配置变量


| 变量名               | 默认值      | 说明                                              |
| -------------------- | ----------- | ------------------------------------------------- |
| `deploy_name`        | `"example"` | 部署名称，用于多集群管理                          |
| `kubernetes_version` | `"v1.32.3"` | Kubernetes 版本 生成 kubeconfig 调用 kubelet 工具 |
| `cfssl_version`      | `"1.6.5"`   | CFSSL 工具版本                                    |

### API 服务器配置


| 变量名                   | 默认值           | 说明                     |
| ------------------------ | ---------------- | ------------------------ |
| `kube_apiserver_lb_addr` | `"127.0.0.1"`    | API 服务器负载均衡器地址 |
| `kube_apiserver_lb_port` | `"6443"`         | API 服务器端口           |
| `service_cidr`           | `"10.96.0.0/12"` | 服务网段 CIDR            |

### 证书配置


| 变量名              | 默认值      | 说明                                                                                                                              |
| ------------------- | ----------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `cert_update_mode`  | `"none"`    | 证书更新模式：<br>`none`- 不更新任何证书<br>`ca_only`- 只更新 CA 证书<br>`components_only`- 只更新组件证书<br>`all`- 更新所有证书 |
| `ca_expiry`         | `"876000h"` | CA 证书有效期（100年）                                                                                                            |
| `cert_expiry`       | `"8760h"`   | 组件证书有效期（1年）                                                                                                             |
| `master_cert_hosts` | `[]`        | API 服务器证书中的额外主机名                                                                                                      |

### 集群配置


| 变量名         | 默认值         | 说明                      |
| -------------- | -------------- | ------------------------- |
| `cluster_name` | `"kubernetes"` | kubeconfig 中的集群名称   |
| `context_name` | `"default"`    | kubeconfig 中的上下文名称 |

## 🚀 使用方式

### 基本用法

1. 在 playbook 中引用角色：

```yaml
- hosts: localhost
  roles:
    - cert-manager
```

2. 使用默认设置生成证书：

```bash
ansible-playbook -i inventory cert-playbook.yml
```

### 初始证书生成

```yaml
- hosts: localhost
  vars:
    deploy_name: "production"
    master_cert_hosts:
      - "api.k8s.example.com"
      - "master.k8s.example.com"
  roles:
    - cert-manager
```

### 证书更新

1. 更新所有证书：

```yaml
- hosts: localhost
  vars:
    deploy_name: "production"
    cert_update_mode: "all"
  roles:
    - cert-manager
```

2. 仅更新组件证书（保留 CA）：

```yaml
- hosts: localhost
  vars:
    deploy_name: "production"
    cert_update_mode: "components_only"
  roles:
    - cert-manager
```

### 高级配置

1. 自定义证书有效期：

```yaml
- hosts: localhost
  vars:
    deploy_name: "production"
    cert_expiry: "17520h"  # 2年有效期
  roles:
    - cert-manager
```

2. 针对高可用集群配置：

```yaml
- hosts: localhost
  vars:
    deploy_name: "ha-cluster"
    kube_apiserver_lb_addr: "10.0.0.100"  # 负载均衡器 IP
    master_cert_hosts:
      - "api.k8s.example.com"
      - "api-int.k8s.example.com"
  roles:
    - cert-manager
```

### 使用标签执行特定任务

1. 仅执行证书更新相关任务：

```bash
ansible-playbook -i inventory cert-playbook.yml --tags "update-certs"
```

2. 仅更新特定组件的证书：

```bash
ansible-playbook -i inventory cert-playbook.yml --tags "kubelet"
```

## 💡 使用内置方法调用

```bash
ansible-playbook -e @deploy/example/config.yml -i deploy/example/hosts playbooks/01.system-init.yml 
```

### 最佳实践

1. **证书备份**：定期备份 `{{ generate_certs_dir }}` 目录中的所有证书和配置文件
2. **证书轮换**：计划定期的证书轮换（例如每年一次）
3. **安全存储**：确保证书和配置文件的安全存储，特别是 CA 密钥
4. **自动化**：将证书生成和更新整合到持续集成/持续部署（CI/CD）流程中
5. **有效期监控**：设置监控以在证书接近过期时提醒

### 故障排除提示

* 如果遇到证书生成问题，检查 CFSSL 工具安装
* 确保 kubectl 版本与目标 Kubernetes 集群兼容
* 证书更新后，可能需要重启相关的 Kubernetes 组件使新证书生效
* 使用 `openssl x509 -in cert.pem -text -noout` 命令查看证书详情和有效期

## ⚠️ 注意事项

* **CA 私钥安全**：CA 私钥（`ca-key.pem`）是最敏感的文件，应特别保护
* **证书备份**：确保在更新证书前有可靠的备份
* **生产环境**：在生产环境中应使用更强的密钥长度（至少 2048 位 RSA）
* **证书依赖**：更改 CA 证书会导致所有已签发的证书失效
* **API 服务器主机名**：确保 API 服务器证书中包含所有可能用于访问 API 的主机名和 IP 地址

---

🔐 通过 `cert-manager` 角色，您可以轻松管理 Kubernetes 集群的整个证书生命周期，确保集群通信安全无忧。

## 作者信息

* 作者：Yan Shicheng
* 邮箱：yans121@sina.com
* github：https://github.com/yanshicheng
