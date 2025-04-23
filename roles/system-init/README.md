# system-init 角色使用说明

# System-Init Role

![系统初始化](https://img.shields.io/badge/%E7%B3%BB%E7%BB%9F%E5%88%9D%E5%A7%8B%E5%8C%96-System%20Init-blue)![Ansible](https://img.shields.io/badge/Ansible-Role-red)![版本](https://img.shields.io/badge/Version-1.0-green)

## 📋 简介

`system-init` 角色用于对Linux服务器进行初始化和优化配置，为后续部署 Kubernetes 集群或其他服务提供标准化、优化的系统环境。该角色实现了一系列系统级别的配置和优化，确保服务器环境符合生产部署的最佳实践要求。

## 🎯 适用场景

* 新服务器的初始化配置
* Kubernetes集群节点的系统准备
* 需要标准化配置的生产环境服务器
* DevOps自动化部署流程中的系统初始化阶段
* 批量服务器环境统一配置

## ✨ 功能说明

角色包含以下核心功能模块，可以通过变量来选择性启用或禁用:

### 🔄 基础配置

* **主机名配置**: 重置主机名并确保符合 Kubernetes 规范
* **时间同步**: 设置时区并同步系统时间
* **软件包安装**:  根据不同操作系统安装必要的基础软件包
* **静态解析配置**:  配置hosts文件以实现集群内节点互相解析

### 🔒 安全配置

* **SELinux管理**: 根据需要禁用SELinux
* **防火墙配置**: 管理系统防火墙
* **审计配置**: 设置系统审计(auditd)

### 🚀 性能优化

* **内核参数优化**: 配置最佳的系统内核参数
* **资源限制优化**: 设置系统资源使用限制
* **SWAP管理**:  禁用交换分区(Kubernetes要求)
* **IPVS配置**:  配置IPVS内核模块(用于Kubernetes服务代理)

### 📊 日志与监控

* **日志系统优化**: 优化 journald 和 syslog 配置
* **历史命令记录优化**: 增强 bash 历史命令记录功能

### 🛠️ 辅助工具配置

* **Vim配置优化**: 配置 Vim 编辑器以提高使用体验
* **NFS客户端配置**: 配置 NFS 客户端(可选)
* **NetworkManager配置**: 优化 NetworkManager 避免与容器网络冲突

## 📝 变量说明

### 基本变量


| 变量名         | 默认值                    | 说明                                        |
| -------------- | ------------------------- | ------------------------------------------- |
| `timezone`     | `"Asia/Shanghai"`         | 系统时区设置                                |
| `hist_size`    | `5000`                    | 历史命令保存数量                            |
| `registry`     | `registry.ikubeops.local` | 安装Kubernetes使用的镜像仓库地址            |
| `registry_ip`  | `""`                      | 镜像仓库IP地址(默认使用Ansible控制节点地址) |
| `custom_hosts` | `[]`                      | 自定义hosts静态解析列表                     |

### 功能开关


| 变量名                             | 默认值  | 说明                  |
| ---------------------------------- | ------- | --------------------- |
| `enable_audit`                     | `true`  | 是否启用系统审计功能  |
| `disable_firewall`                 | `true`  | 是否禁用防火墙        |
| `disable_selinux`                  | `true`  | 是否禁用SELinux       |
| `enable_ipvs`                      | `true`  | 是否加载IPVS内核模块  |
| `enable_history_optimization`      | `true`  | 是否优化历史命令配置  |
| `enable_log_optimization`          | `true`  | 是否优化日志配置      |
| `enable_kernel_optimization`       | `true`  | 是否优化内核参数      |
| `enable_system_limit_optimization` | `true`  | 是否优化系统资源限制  |
| `enable_nfs_client`                | `false` | 是否启用NFS客户端配置 |
| `enable_install_packages`          | `true`  | 是否安装基础软件包    |
| `enable_reset_hostname`            | `true`  | 是否重置主机名        |
| `enable_timezone`                  | `true`  | 是否设置时区          |
| `enable_vim_optimization`          | `true`  | 是否优化Vim配置       |

### 高级变量

上述变量可在`defaults/main.yml`中找到。此外，系统参数、内核模块和软件包等配置位于`vars/`目录下的系统特定配置文件中：

* `vars/main.yml`: 通用系统参数和内核模块配置
* `vars/RedHat.yml`: RedHat系列(CentOS, RHEL等)特定配置
* `vars/Debian.yml`: Debian系列(Ubuntu, Debian)特定配置

## 🚀 使用方式

### 基本用法

1. 在你的playbook中引用该角色:

```yaml
- hosts: all
  roles:
    - system-init
```

2. 使用自定义变量:

```yaml
- hosts: all
  roles:
    - role: system-init
      vars:
        timezone: "Europe/London"
        enable_nfs_client: true
        custom_hosts:
          - ip: "192.168.1.100"
            hostname: "master.example.com"
```

### 高级用法

1. 仅运行特定任务(使用标签):

```bash
ansible-playbook playbook.yml --tags "packages,firewall,selinux"
```

2. 排除特定任务:

```bash
ansible-playbook playbook.yml --skip-tags "nfs,swap"
```

3. 与其他角色组合使用(K8s部署示例):

```yaml
- hosts: k8s_nodes
  roles:
    - system-init
    - docker-install
    - kubernetes-install
```

4. 针对不同环境使用不同配置(使用组变量):

```yaml
# 在group_vars/production.yml中
system-init:
  enable_audit: true
  disable_firewall: false
  
# 在group_vars/development.yml中
system-init:
  enable_audit: false
  enable_nfs_client: true

# 在playbook中
- hosts: production
  roles:
    - role: system-init
      vars: "{{ system-init }}"
```

## 💡 使用内置方法调用

```bash
ansible-playbook -e @deploy/example/config.yml -i deploy/example/hosts playbooks/01.system-init.yml 
```

## ⚠️ 注意事项

* 禁用SELinux和防火墙可能会降低系统安全性，请根据实际环境需求配置
* 某些内核参数优化可能不适用于所有环境，请根据服务器角色和硬件配置进行调整
* 重启某些服务(如NetworkManager)可能会导致网络连接暂时中断

## 作者信息

* 作者：Yan Shicheng
* 邮箱：yans121@sina.com
* github：https://github.com/yanshicheng
