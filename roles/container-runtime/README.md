# Container-Runtime 角色

![容器运行时](https://img.shields.io/badge/%E5%AE%B9%E5%99%A8%E8%BF%90%E8%A1%8C%E6%97%B6-Container--Runtime-blue)![Docker](https://img.shields.io/badge/Docker-%E6%94%AF%E6%8C%81-brightgreen)![Containerd](https://img.shields.io/badge/Containerd-%E6%94%AF%E6%8C%81-brightgreen)![Kubernetes](https://img.shields.io/badge/Kubernetes-%E5%AE%B9%E5%99%A8%E7%BC%96%E6%8E%92-orange)

## 📋 简介

`container-runtime` 角色负责在 Kubernetes 集群节点上安装和配置容器运行时环境。该角色支持两种主流容器运行时 - Docker 和 Containerd，可根据集群需求灵活选择。通过统一的安装流程和配置管理，确保所有节点具有一致、稳定的容器运行环境，为 Kubernetes 集群提供可靠的容器服务基础。

本角色内置了完整的前置检查、环境准备、安装配置、服务管理和安全设置，可以无缝集成到 Kubernetes 集群部署流程中，支持多种 Linux 发行版和系统架构。

## 🎯 适用场景

* **新建 Kubernetes 集群**：为全新集群提供标准化的容器运行时环境
* **集群节点扩容**：保证新增节点与现有节点的容器环境一致
* **运行时升级与迁移**：支持从旧版本升级或在 Docker 与 Containerd 之间迁移
* **私有云/混合云环境**：适用于企业内部数据中心或混合云场景
* **生产环境标准化**：确保开发、测试、生产环境的容器运行时配置一致
* **离线安装环境**：支持完全离线环境下的部署
* **多架构支持**：同时支持 x86\_64、ARM64 等多种硬件架构

## ✨ 功能说明

### 🐳 多运行时支持

* **Docker**：完整安装 Docker 引擎，包括 Docker CLI、dockerd 服务和 containerd
* **Containerd**：直接安装 Containerd 作为容器运行时，更轻量高效
* **CRI-Docker**：可选安装 CRI-Docker 适配器，实现 Docker 与 Kubernetes CRI 的对接

### 🔧 核心组件安装

* **运行时引擎**：Docker（dockerd）或 Containerd
* **底层组件**：runc 容器运行时、CNI 插件
* **管理工具**：crictl（容器运行时命令行）

### 🧰 辅助工具安装（可选）

* **nerdctl**：Containerd 原生命令行工具，类似于 Docker CLI
* **buildkit**：高性能容器镜像构建工具
* **cri-docker**：使 Docker 支持 Kubernetes CRI 接口

### 🔐 安全与镜像仓库配置

* **镜像仓库认证**：支持配置私有镜像仓库访问凭证
* **TLS/SSL 证书**：自动配置镜像仓库的 TLS 证书
* **镜像仓库白名单**：可配置不同安全策略的镜像源

### 🛠️ 高级功能

* **自动检测系统**：根据操作系统类型和架构自动选择合适的软件包
* **服务管理**：配置并启用系统服务单元
* **备份与恢复**：配置更改前自动备份原有配置
* **沙箱镜像配置**：支持自定义 Pause 容器镜像
* **节点资源优化**：针对容器运行时的资源使用进行优化

### 📊 监控与日志

* **服务状态检测**：安装后自动验证服务状态
* **日志配置**：优化容器日志存储和轮转设置
* **安装报告**：提供详细的安装摘要和状态报告

## 📝 变量说明

### 核心配置变量


| 变量名              | 默认值                      | 说明                                           |
| ------------------- | --------------------------- | ---------------------------------------------- |
| `container_runtime` | `"docker"`                  | 容器运行时类型，可选`"docker"`或`"containerd"` |
| `container_version` | `"28.0.4"`                  | 容器运行时版本                                 |
| `base_dir`          | `"/opt/kubernetes"`         | 安装基础目录                                   |
| `registry`          | `"registry.ikubeops.local"` | 默认镜像仓库地址                               |
| `registry_project`  | `"ikubeops"`                | 镜像仓库项目名                                 |

### 组件版本变量


| 变量名                | 默认值     | 说明                  |
| --------------------- | ---------- | --------------------- |
| `runc_version`        | `"1.2.6"`  | runc 版本             |
| `cni_plugins_version` | `"1.6.2"`  | CNI 插件版本          |
| `crictl_version`      | `"1.31.1"` | crictl 工具版本       |
| `nerdctl_version`     | `"2.0.4"`  | nerdctl 工具版本      |
| `buildkit_version`    | `"0.20.1"` | buildkit 版本         |
| `cri_docker_version`  | `"0.3.17"` | cri-docker 适配器版本 |

### 镜像仓库配置


| 变量名                          | 默认值     | 说明                          |
| ------------------------------- | ---------- | ----------------------------- |
| `container_registry_mirrors`    | `[]`       | 配置镜像仓库加速地址          |
| `container_insecure_registries` | 见默认配置 | 配置不安全或私有镜像仓库      |
| `containerd_registry_configs`   | `{}`       | Containerd 镜像仓库高级配置   |
| `sandbox_image`                 | 自动生成   | Kubernetes pause 容器镜像地址 |

### 可选组件控制


| 变量名               | 默认值 | 说明                       |
| -------------------- | ------ | -------------------------- |
| `install_crictl`     | `true` | 是否安装 crictl 工具       |
| `install_nerdctl`    | `true` | 是否安装 nerdctl 工具      |
| `install_buildkit`   | `true` | 是否安装 buildkit 工具     |
| `install_cri_docker` | `true` | 是否安装 cri-docker 适配器 |

### 安装行为控制


| 变量名                              | 默认值  | 说明                       |
| ----------------------------------- | ------- | -------------------------- |
| `skip_container_install_if_running` | `false` | 如服务已运行是否跳过安装   |
| `restart_on_change`                 | `true`  | 配置变更时是否自动重启服务 |
| `wait_for_service`                  | `true`  | 是否等待服务启动完成       |
| `service_start_timeout`             | `180`   | 服务启动超时时间（秒）     |
| `fail_on_file_missing`              | `true`  | 缺少文件时是否失败退出     |
| `force_reinstall`                   | `false` | 是否强制重新安装           |

### Docker 特定配置


| 变量名                | 默认值            | 说明                   |
| --------------------- | ----------------- | ---------------------- |
| `docker_live_restore` | `true`            | 启用 Docker 热重启功能 |
| `docker_bip`          | `"172.17.0.1/16"` | Docker 网桥 IP 设置    |
| `docker_log_max_size` | `"100m"`          | 容器日志最大大小       |
| `docker_log_max_file` | `"3"`             | 容器日志文件数量       |

## 🚀 使用方式

### 基本用法

1. 在 playbook 中引用角色:

```yaml
- hosts: k8s_nodes
  roles:
    - container-runtime
```

2. 指定容器运行时类型:

```yaml
- hosts: k8s_nodes
  roles:
    - role: container-runtime
      vars:
        container_runtime: "containerd"  # 或 "docker"
```

### 高级配置示例

1. 使用 Containerd + 自定义组件版本:

```yaml
- hosts: k8s_nodes
  roles:
    - role: container-runtime
      vars:
        container_runtime: "containerd"
        container_version: "1.7.11"
        runc_version: "1.2.6"
        cni_plugins_version: "1.6.2"
        install_nerdctl: true
        install_buildkit: false
```

2. 使用 Docker + CRI 适配器 + 自定义镜像仓库:

```yaml
- hosts: k8s_nodes
  roles:
    - role: container-runtime
      vars:
        container_runtime: "docker"
        container_version: "28.0.4"
        install_cri_docker: true
        container_registry_mirrors:
          - registry: "docker.io"
            endpoints: 
              - "https://mirror.example.com"
        container_insecure_registries:
          - hosts: "https://registry.company.com"
            cert_auth: true
```

3. 使用标签安装特定组件:

```bash
# 仅安装 Docker 运行时，不配置 CRI 适配器
ansible-playbook -i inventory playbook.yml --tags "install" --skip-tags "cri-docker"

# 仅更新配置，不重新安装二进制文件
ansible-playbook -i inventory playbook.yml --tags "config"
```

### 多环境部署

使用不同的变量文件为不同环境配置:

```yaml
# 开发环境: group_vars/dev.yml
container_runtime: "docker"
install_buildkit: true
docker_experimental: true

# 生产环境: group_vars/prod.yml
container_runtime: "containerd"
install_buildkit: false
fail_on_file_missing: true
```

在 playbook 中引用:

```yaml
- hosts: dev_clusters
  vars_files:
    - group_vars/dev.yml
  roles:
    - container-runtime

- hosts: prod_clusters
  vars_files:
    - group_vars/prod.yml
  roles:
    - container-runtime
```

### 安装后验证

安装完成后，可以使用以下命令验证容器运行时是否正常工作:

```bash
# Docker
systemctl status docker
docker info

# Containerd
systemctl status containerd
crictl info
```

如果安装了 CRI-Docker，还可以验证:

```bash
systemctl status cri-docker
ls -la /var/run/cri-dockerd/cri-dockerd.sock
```

### 镜像仓库配置示例

配置镜像仓库加速:

```yaml
container_registry_mirrors:
  - registry: "docker.io"
    endpoints:
      - "https://docker.mirrors.ustc.edu.cn"
      - "https://registry-1.docker.io"
  - registry: "k8s.gcr.io"
    endpoints:
      - "https://registry.aliyuncs.com/k8sxio"
```

配置私有仓库:

```yaml
container_insecure_registries:
  - hosts: "https://harbor.company.com"
    cert_auth: true
  - hosts: "http://registry.local:5000"
    cert_auth: false
```

## ⚠️ 注意事项

* 在生产环境中更改容器运行时前，请确保先备份重要数据
* 对于已有 Kubernetes 集群，更改容器运行时可能需要重新配置节点
* 确保防火墙和安全组规则允许容器间通信（特别是 CNI 网络）
* 部署前请确认系统满足最低要求（内核版本、存储驱动等）
* 使用 CRI-Docker 时，需确保该组件与 Kubernetes 版本兼容
* Docker 和 Containerd 使用不同的数据存储路径，迁移时需注意数据迁移

---

🔄 更多详细配置请参考具体任务文件和模板文件中的注释说明。
