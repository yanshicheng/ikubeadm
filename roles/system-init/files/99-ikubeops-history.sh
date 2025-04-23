      #!/bin/bash
      #File Name    : /etc/profile.d/history.sh
      #Author       : Yan Shicheng
      #Mail         : yans121@sina.com
      #Create Time  : 2022-06-21 22:31
      #Description  : Bash 历史命令优化
      
      # 增加历史命令数量上限
      HISTSIZE=5000
      HISTFILESIZE=5000
      
      # 添加时间戳和用户信息
      export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S `whoami` "