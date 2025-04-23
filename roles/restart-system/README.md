# Restart 角色

![重启](https://img.shields.io/badge/%E7%B3%BB%E7%BB%9F-%E9%87%8D%E5%90%AF-red)![管理](https://img.shields.io/badge/%E6%9C%8D%E5%8A%A1%E5%99%A8-%E7%AE%A1%E7%90%86-blue)![运维](https://img.shields.io/badge/%E8%BF%90%E7%BB%B4-%E5%B7%A5%E5%85%B7-green)

## 📋 简介

`restart` 角色用于安全、可控地重启 Kubernetes 集群中的节点服务器。该角色使用 Ansible 的内置 `reboot` 模块，确保重启过程可靠、可预测且可监控，最小化集群维护期间的停机风险。

重启过程包括预重启延迟、重启超时控制和重启后验证，确保服务器能够按照预期完成重启并恢复正常功能，是集群维护和更新后必不可少的操作工具。

## 🎯 适用场景

* **系统更新后重启**：内核或系统包更新后需要重启以应用更改
* **集群滚动更新**：在 Kubernetes 集群维护中进行滚动重启
* **硬件变更后**：添加或更换硬件后需要重启服务器
* **性能问题排查**：解决系统资源耗尽或性能下降问题
* **计划内维护**：定期进行的系统维护工作
* **配置更改后应用**：某些系统层面的配置更改需要重启生效
* **节点异常恢复**：当节点出现异常但仍然可访问时进行重启恢复
* **安全补丁应用**：安装关键安全补丁后进行必要的重启

## ✨ 功能说明

### 🔄 重启流程控制

* **预重启延迟**：重启前等待一段时间，以便应用程序优雅退出
* **重启消息通知**：设置清晰的重启原因，便于审计和跟踪
* **超时控制**：设定最长等待时间，防止重启过程卡住
* **重启后验证**：通过测试命令确认系统已成功重启并正常运行
* **重启后延迟**：重启后等待足够时间，确保所有服务完全启动

### 🛡️ 安全保障

* **可控性**：通过 Ansible 的任务执行模式，确保重启过程可控
* **可追溯**：记录重启操作的发起人和原因
* **成功验证**：确认系统重启后的可用性
* **顺序控制**：可与其他角色配合，实现节点的有序重启

## 📝 变量说明

该角色没有在 `defaults/main.yml` 中定义变量，但在任务文件中使用了以下内置参数：


| 参数名              | 默认值                      | 说明                           |
| ------------------- | --------------------------- | ------------------------------ |
| `reboot_timeout`    | `300`                       | 等待重启完成的最长时间（秒）   |
| `msg`               | `"由Ansible触发的计划重启"` | 重启事件的描述信息             |
| `pre_reboot_delay`  | `5`                         | 发出重启命令前的等待时间（秒） |
| `post_reboot_delay` | `30`                        | 系统重启后的额外等待时间（秒） |
| `test_command`      | `whoami`                    | 验证重启成功的测试命令         |

## 🚀 使用方式

### 基本用法

在 playbook 中引用该角色:

```yaml
- hosts: all
  roles:
    - restart
```

### 针对特定主机组重启

```yaml
- hosts: worker_nodes
  roles:
    - restart
```

### 与其他操作结合使用

```yaml
- hosts: k8s_nodes
  serial: 1  # 一次只处理一台主机，实现滚动重启
  roles:
    - system-updates  # 先执行系统更新
    - restart         # 然后重启系统
```

### 自定义重启参数

```yaml
- hosts: database_servers
  tasks:
    - name: 重启数据库服务器
      include_role:
        name: restart
      vars:
        reboot_timeout: 600       # 增加超时时间
        pre_reboot_delay: 30      # 增加预重启延迟，让应用优雅关闭
        post_reboot_delay: 120    # 增加后重启延迟，确保所有服务完全启动
        msg: "数据库服务器例行维护重启"
```

### 条件重启

```yaml
- hosts: all
  tasks:
    - name: 检查是否需要重启
      shell: needs-restarting -r
      register: needs_restarting
      failed_when: false
      changed_when: false
    
    - name: 仅在需要时重启服务器
      include_role:
        name: restart
      when: needs_restarting.rc == 1
```

### 分批重启

```yaml
- hosts: k8s_workers
  serial: "25%"  # 一次重启 25% 的节点
  roles:
    - restart
```

### 注意事项

* **生产环境谨慎使用**：确保了解重启对服务可用性的影响
* **配合排空节点**：Kubernetes 集群重启前先执行 `kubectl drain` 排空节点
* **设置适当的超时**：根据服务器启动时间调整 `reboot_timeout` 和 `post_reboot_delay`
* **避免同时重启**：使用 `serial` 参数避免同时重启过多节点
* **重启后验证**：重启后验证关键服务是否正常运行
* **通知机制**：重要系统重启前通知相关团队
* **维护窗口**：在计划的维护窗口内执行重启

---

📢 通过合理使用 `restart` 角色，您可以安全可靠地进行系统重启操作，最大限度减少重启过程对业务的影响。
