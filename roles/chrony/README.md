# Ansible Role: Chrony

# Chrony 角色

![时间同步](https://img.shields.io/badge/%E6%97%B6%E9%97%B4%E5%90%8C%E6%AD%A5-Chrony-blue)![Ansible](https://img.shields.io/badge/Ansible-Role-red)![版本](https://img.shields.io/badge/Version-1.0-green)

## 📋 简介

`chrony` 角色用于部署和管理 Chrony 时间同步服务，它是现代 Linux 系统上 NTP 的替代品，提供更高精度和更好的稳定性。该角色支持将服务器配置为 NTP 服务器或客户端，确保系统时间在集群内部或与外部权威时间源保持同步。

与传统的 NTP 相比，Chrony 在不稳定网络条件下表现更好，启动后能更快地同步时间，并且能够处理间歇性连接和变化的时钟频率（特别适用于虚拟环境）。

## 🎯 适用场景

* **服务器集群环境**：确保集群内所有节点时间一致
* **Kubernetes 集群**：为容器编排和分布式系统提供时间同步
* **数据库服务器**：需要精确时间戳的事务处理系统
* **虚拟化环境**：解决虚拟机时钟漂移问题
* **安全敏感系统**：需要精确时间记录的审计和日志系统
* **边缘计算设备**：间歇性连接互联网的设备
* **替换传统 NTP 服务**：从旧式 NTP 服务迁移到更现代的时间同步解决方案

## ✨ 功能说明

### 🔄 基础功能

* **双重角色支持**：可配置为 NTP 服务器或客户端
* **智能模式切换**：根据主机组和变量自动选择合适的配置模式
* **自动检测**：识别并应用适合当前操作系统的配置

### 🔧 服务器模式功能

* **上游时间源配置**：支持配置多个外部 NTP 服务器
* **访问控制**：可限制允许同步的客户端网络
* **本地层级设置**：当无法连接外部时间源时提供备用时间服务
* **防火墙自动配置**：可选择性地配置防火墙规则

### 📱 客户端模式功能

* **自动服务器发现**：自动连接到 Ansible 清单中定义的 Chrony 服务器
* **备份服务器机制**：当内部服务器不可用时回退到公共 NTP 服务器
* **步进时间校正**：大偏差时允许时间步进而非缓慢调整
* **RTC 同步**：与硬件时钟保持同步

### 🛠️ 高级功能

* **服务健康检查**：部署后验证服务状态和同步情况
* **硬件时间戳支持**：可配置特定网络接口的硬件时间戳
* **安全配置选项**：支持 NTP 身份验证
* **日志功能**：支持详细的追踪、测量和统计日志

## 📝 变量说明

### 基本配置变量


| 变量名               | 默认值                             | 说明                       |
| -------------------- | ---------------------------------- | -------------------------- |
| `chrony_server_mode` | `true`                             | 是否启用服务器模式         |
| `chrony_driftfile`   | `/var/lib/chrony/drift`            | 记录时钟频率偏差的文件路径 |
| `chrony_log_dir`     | `/var/log/chrony`                  | 日志目录                   |
| `chrony_rtcsync`     | `true`                             | 是否启用实时时钟同步       |
| `chrony_log_options` | `tracking measurements statistics` | 日志记录选项               |

### 服务器配置变量


| 变量名                      | 默认值                                     | 说明                                 |
| --------------------------- | ------------------------------------------ | ------------------------------------ |
| `chrony_allow_networks`     | `["127.0.0.1/32", "::1/128", "0.0.0.0/0"]` | 允许访问 NTP 服务的网络列表          |
| `chrony_local_stratum`      | `10`                                       | 本地层级值（当无法连接上游服务器时） |
| `chrony_configure_firewall` | `false`                                    | 是否自动配置防火墙规则               |

### 时间源配置变量


| 变量名                          | 默认值                                                      | 说明                         |
| ------------------------------- | ----------------------------------------------------------- | ---------------------------- |
| `chrony_ntp_servers`            | `[{"server": "ntp1.aliyun.com", "options": "iburst"}, ...]` | 上游 NTP 服务器列表          |
| `chrony_hwtimestamp_interfaces` | `[]`                                                        | 启用硬件时间戳的网络接口列表 |

### 时间调整变量


| 变量名                      | 默认值  | 说明                                     |
| --------------------------- | ------- | ---------------------------------------- |
| `chrony_makestep_threshold` | `1.0`   | 时间跳变阈值（秒）                       |
| `chrony_makestep_limit`     | `3`     | 允许的最大时间跳变次数                   |
| `chrony_maxupdateskew`      | `100.0` | 最大更新偏差（防止错误估计影响系统时钟） |

### 客户端专用变量


| 变量名                         | 默认值 | 说明                 |
| ------------------------------ | ------ | -------------------- |
| `chrony_client_ignore_stratum` | `true` | 是否忽略源层级权重   |
| `chrony_leapsectz`             | `true` | 是否启用闰秒时区支持 |

### 安全变量


| 变量名                      | 默认值                          | 说明                         |
| --------------------------- | ------------------------------- | ---------------------------- |
| `chrony_use_authentication` | `false`                         | 是否启用 NTP 身份验证        |
| `chrony_key_id`             | `1`                             | 认证密钥 ID                  |
| `chrony_key_value`          | `ChangeThisToASecureKeyInVault` | 认证密钥值（应替换为安全值） |

## 🚀 使用方式

### 基本用法

1. 在 Ansible 清单文件中定义 Chrony 服务器组：

```ini
[chrony]
chrony-server-1
chrony-server-2

[app_servers]
app-server-1
app-server-2
```

2. 在 playbook 中应用角色：

```yaml
- hosts: all
  roles:
    - chrony
```

### 服务器模式配置

```yaml
- hosts: chrony
  vars:
    chrony_server_mode: true
    chrony_allow_networks:
      - "10.0.0.0/8"
      - "172.16.0.0/12"
      - "192.168.0.0/16"
    chrony_configure_firewall: true
  roles:
    - chrony
```

### 客户端模式配置

```yaml
- hosts: app_servers
  vars:
    chrony_server_mode: false
    chrony_makestep_threshold: 0.5
    chrony_makestep_limit: 5
  roles:
    - chrony
```

### 高级用法

1. 使用自定义 NTP 服务器：

```yaml
- hosts: all
  vars:
    chrony_ntp_servers:
      - server: "ntp.example.com"
        options: "iburst prefer"
      - server: "time.example.org"
        options: "iburst"
  roles:
    - chrony
```

2. 启用 NTP 认证：

```yaml
- hosts: all
  vars:
    chrony_use_authentication: true
    chrony_key_id: 42
    chrony_key_value: "{{ vault_chrony_key }}" # 使用 Ansible Vault 存储密钥
  roles:
    - chrony
```

3. 仅运行特定任务（使用标签）：

```bash
ansible-playbook playbook.yml --tags "configure,service"
```

4. 针对不同环境使用不同的 NTP 源：

```yaml
# group_vars/production.yml
chrony_ntp_servers:
  - server: "time.production.example.com"
    options: "iburst"

# group_vars/development.yml
chrony_ntp_servers:
  - server: "time.dev.example.com"
    options: "iburst"
```

### 最佳实践

* 至少配置 3-4 个 NTP 服务器以提高可靠性
* 在内部网络中设置 2-3 个 Chrony 服务器作为时间源
* 使用 `iburst` 选项加速初始同步
* 定期检查 Chrony 状态：`chronyc tracking` 和 `chronyc sources -v`
* 考虑使用地理位置接近的公共 NTP 池服务器
* 为重要的环境启用防火墙规则，限制 NTP 访问

### 监控与验证

部署完成后，可以使用以下命令检查同步状态：

```bash
# 查看时间源状态
chronyc sources -v

# 查看当前同步详情
chronyc tracking

# 检查 Chrony 活动
journalctl -u chronyd
```

## ⚠️ 注意事项

* 变更系统时间可能会影响正在运行的应用程序
* 启用身份验证需要确保所有客户端和服务器配置匹配
* 在虚拟环境中，虚拟机时钟可能会漂移，建议合理配置 `makestep` 参数
* 防火墙配置需要确保 UDP 端口 123 可访问
* 避免在同一网络中混合使用不同的时间同步服务（如 ntpd 和 chronyd）

---

🔧 如有任何问题或建议，请联系您的系统管理员或项目负责人。

这个 Ansible 角色用于安装和配置 Chrony NTP 服务，支持服务器和客户端模式。Chrony 是一个实现网络时间协议 (NTP) 的软件，可以保持系统时钟与参考时间源同步。

## 功能特点

* 支持服务器和客户端两种部署模式
* 通过 `CHRONY_SERVER_DEPLOY` 变量灵活控制部署模式
* 自动安装和配置 Chrony
* 灵活的服务器时间源配置
* 自动配置防火墙规则（可选）
* 支持多种 Linux 发行版（RHEL/CentOS 7/8/9、Debian、Ubuntu）
* 客户端智能选择可用的 NTP 服务器
* 使用标签可以单独部署服务器或客户端

## 系统要求

* Ansible 2.9 或更高版本
* 支持的操作系统:
  * RHEL/CentOS 7/8/9
  * Debian 11/12 (Bullseye/Bookworm)
  * Ubuntu 18.04/20.04/22.04 (Bionic/Focal/Jammy)

## 主要变量

### 通用配置

```yaml
# 配置文件路径
chrony_driftfile: "/var/lib/chrony/drift"
chrony_log_dir: "/var/log/chrony"

# 防火墙配置
chrony_configure_firewall: false # 是否配置防火墙

# 部署控制
CHRONY_SERVER_DEPLOY: true  # 设置为 true 部署服务端，false 部署客户端
```

### 服务器配置

```yaml
# 服务器配置选项
chrony_server_mode: true # 设置为 true 启用服务器模式
chrony_allow_networks:
  - "127.0.0.1/32" # 本地回环地址
  - "::1/128" # IPv6 本地回环地址
  - "0.0.0.0/0" # 允许所有网络访问（谨慎使用）
  # - "192.168.0.0/24" # 内网示例

# 上游 NTP 服务器列表
chrony_ntp_servers:
  - server: "ntp1.aliyun.com"
    options: "iburst"
  - server: "time1.cloud.tencent.com"
    options: "iburst"
  - server: "0.cn.pool.ntp.org"
    options: "iburst"

# 高级选项
chrony_makestep_threshold: 1.0 # 时间跳变阈值（秒）
chrony_makestep_limit: 3 # 允许的最大时间跳变次数
chrony_rtcsync: true # 是否启用实时时钟同步
chrony_local_stratum: 10 # 本地层级（当无法连接到上游服务器时）
```

## 清单文件示例

```ini
# NTP 服务器节点
[chrony]
ntp-server-1 CHRONY_SERVER_DEPLOY=true  # 部署 chrony 服务端
ntp-server-2 CHRONY_SERVER_DEPLOY=false # 不部署 chrony 服务端（已经部署过）

# 客户端节点
[clients]
client-1
client-2
client-3
```

## Playbook 示例

### 完整部署（服务器和客户端）

```yaml
---
- name: 配置 Chrony NTP 服务器
  hosts: chrony
  become: true
  roles:
    - chrony

- name: 配置 Chrony 客户端
  hosts: all:!chrony
  become: true
  roles:
    - chrony
```

### 仅部署服务器或客户端

```yaml
---
- name: 配置 Chrony NTP 服务
  hosts: all
  become: true
  roles:
    - role: chrony
      tags: [ server ]  # 使用 server 或 client 标签
```

## 标签

此角色提供以下标签：

* `chrony` - 应用于所有任务
* `install` - 仅安装 Chrony 软件包
* `configure` - 仅配置 Chrony
* `firewall` - 仅配置防火墙
* `service` - 仅管理 Chrony 服务
* `server` - 服务器特定任务
* `client` - 客户端特定任务

## 部署选项

1. 完整部署：
   ```bash
   ansible-playbook playbook.yml
   ```
2. 仅部署服务器：
   ```bash
   ansible-playbook playbook.yml --tags "server"
   ```
3. 仅部署客户端：
   ```bash
   ansible-playbook playbook.yml --tags "client"
   ```
4. 仅配置防火墙：
   ```bash
   ansible-playbook playbook.yml --tags "firewall"
   ```

## 故障排除

1. 检查 Chrony 服务状态：
   ```bash
   systemctl status chronyd
   ```
2. 检查同步状态：
   ```bash
   chronyc tracking
   ```
3. 检查时间源：
   ```bash
   chronyc sources
   ```
4. 检查日志：
   ```bash
   # RHEL/CentOS
   journalctl -u chronyd
   # Debian/Ubuntu
   journalctl -u chrony
   ```

## 特别说明

* 对于已经部署过 Chrony 服务端的主机，可以设置 `CHRONY_SERVER_DEPLOY=false` 避免重复部署
* 角色会自动识别操作系统类型并应用相应的配置
* 默认配置适用于大多数场景，可按需调整变量

## 作者

该角色由 Yan Shicheng 创建

## 许可证

MIT
