# 系统安全与服务管理命令手册

## 目录
1. [SELinux 管理](#1-selinux-管理)
2. [防火墙 (Firewalld/nftables)](#2-防火墙-firewalldnftables)
3. [Fail2Ban 防护](#3-fail2ban-防护)
4. [ClamAV 防病毒](#4-clamav-防病毒)
5. [Chrony NTS 安全时间同步](#5-chrony-nts-安全时间同步)
6. [服务管理](#6-服务管理)
7. [补充工具](#7-补充工具)

## 1. SELinux 管理

### 作用

SELinux（Security-Enhanced Linux）是Linux内核的一个安全模块，提供强制访问控制（MAC）机制。它通过限制进程和用户对系统资源的访问来增强系统安全性，即使在标准Linux DAC（自主访问控制）被绕过的情况下也能提供保护。

### 部署

SELinux通常在大多数现代Linux发行版中默认安装。要检查SELinux是否已安装并启用：

```bash
# 检查SELinux状态
sestatus

# 检查SELinux内核模块是否加载
lsmod | grep selinux
```

如果没有安装SELinux，可以通过以下方式安装：

```bash
# 在RHEL/CentOS上安装
sudo yum install selinux-policy selinux-policy-targeted policycoreutils

# 在Ubuntu/Debian上安装
sudo apt-get install selinux-basics selinux-policy-default
```

### 常用命令

#### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 查看SELinux状态 | `sestatus`<br>`getenforce` | 检查当前SELinux模式 |
| 启用 Enforcing 模式 | `sudo setenforce 1`<br>`sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config` | 需重启生效 |
| 临时切换 Permissive | `sudo setenforce 0` | 调试用，不阻止仅记录 |
| 列出布尔值设置 | `getsebool -a` | 查看所有SELinux布尔值 |

#### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 查看拒绝日志 | `sudo ausearch -m avc -ts recent`<br>`sudo sealert -a /var/log/audit/audit.log` | 分析 SELinux 拒绝事件 |
| 查看SELinux日志 | `journalctl -u auditd` | 查看审计服务日志 |

#### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 修改文件上下文 | `sudo chcon -t httpd_sys_content_t /path/to/file`<br>`sudo restorecon -Rv /path` | 修复权限问题 |
| 添加自定义策略 | `sudo audit2allow -a -M mypolicy`<br>`sudo semodule -i mypolicy.pp` | 根据日志生成策略模块 |

### 最佳实践

1. **避免完全禁用SELinux**：尽量使用Permissive模式进行调试，而不是完全禁用
   ```bash
   # 错误做法 - 完全禁用SELinux
   sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
   
   # 正确做法 - 使用Permissive模式进行调试
   sudo setenforce 0
   # 调试完成后恢复Enforcing模式
   sudo setenforce 1
   ```

2. **使用sealert工具分析拒绝事件**：当遇到拒绝事件时，使用`sealert`分析并生成解决方案
   ```bash
   # 查看最近的拒绝事件
   sudo ausearch -m avc -ts recent
   
   # 使用sealert分析日志并生成解决方案
   sudo sealert -a /var/log/audit/audit.log
   ```

3. **定期审查自定义策略**：定期检查自定义策略是否仍然必要
   ```bash
   # 列出所有自定义策略模块
   sudo semodule -l | grep -v "^[a-z]"
   
   # 删除不再需要的策略模块
   sudo semodule -r mypolicy
   ```

## 2. 防火墙 (Firewalld/nftables)

### 作用

Firewalld是Linux系统中动态管理防火墙规则的工具，它提供了一个更高级别的防火墙管理接口。nftables是Linux内核中的新一代包分类框架，提供了更灵活和高效的包过滤能力。Firewalld可以使用nftables作为后端来管理防火墙规则。

### 部署

大多数现代Linux发行版默认安装Firewalld。要检查和启用Firewalld：

```bash
# 检查Firewalld状态
sudo systemctl status firewalld

# 启用并启动Firewalld
sudo systemctl enable --now firewalld

# 检查默认区域
sudo firewall-cmd --get-default-zone
```

如果需要安装Firewalld：

```bash
# 在RHEL/CentOS上安装
sudo yum install firewalld

# 在Ubuntu/Debian上安装
sudo apt-get install firewalld
```

### 常用命令

#### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 开放端口 | `sudo firewall-cmd --add-port=80/tcp --permanent`<br>`sudo firewall-cmd --reload` | 永久生效 |
| 开放服务 | `sudo firewall-cmd --add-service=http --permanent` | 服务名见 `/usr/lib/firewalld/services/` |
| 查看活跃区域 | `sudo firewall-cmd --get-active-zones` | 显示当前活跃的区域 |
| 重载防火墙规则 | `sudo firewall-cmd --reload` | 重新加载配置 |

#### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 查看规则 | `sudo firewall-cmd --list-all`<br>`sudo nft list ruleset` | 分别对应 firewalld 和 nftables |
| 查看默认区域 | `sudo firewall-cmd --get-default-zone` | 显示默认区域设置 |

#### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 直接使用 nftables | `sudo nft add rule inet filter input tcp dport 22 accept` | 手动添加规则 |
| 封禁 IP | `sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="1.2.3.4" drop'` | 永久封禁 |
| 查看运行时配置 | `sudo firewall-cmd --list-all --zone=public` | 查看特定区域配置 |

### 最佳实践

1. **最小化开放端口**：只开放必要的端口和服务
   ```bash
   # 检查当前开放的端口
   sudo firewall-cmd --list-ports
   
   # 移除不必要的端口
   sudo firewall-cmd --remove-port=8080/tcp --permanent
   sudo firewall-cmd --reload
   ```

2. **使用服务而非端口**：优先使用服务名称而不是端口号
   ```bash
   # 推荐做法 - 使用服务名称
   sudo firewall-cmd --add-service=http --permanent
   sudo firewall-cmd --add-service=https --permanent
   
   # 不推荐做法 - 直接使用端口号
   sudo firewall-cmd --add-port=80/tcp --permanent
   sudo firewall-cmd --add-port=443/tcp --permanent
   ```

3. **定期审查规则**：定期检查防火墙规则，移除不必要的规则
   ```bash
   # 查看所有规则
   sudo firewall-cmd --list-all
   
   # 移除不再需要的规则
   sudo firewall-cmd --remove-service=ftp --permanent
   sudo firewall-cmd --reload
   ```

## 3. Fail2Ban 防护

### 作用

Fail2Ban是一个入侵防护软件框架，可以保护计算机服务器免受暴力破解攻击。它通过监控系统日志文件，检测多次失败的登录尝试，并自动更新防火墙规则以拒绝攻击者的IP地址，从而提高系统的安全性。

### 部署

Fail2Ban需要手动安装，通常不默认包含在系统中：

```bash
# 在RHEL/CentOS上安装
sudo yum install fail2ban

# 在Ubuntu/Debian上安装
sudo apt-get install fail2ban

# 启用并启动Fail2Ban
sudo systemctl enable --now fail2ban

# 检查Fail2Ban状态
sudo systemctl status fail2ban
```

### 常用命令

#### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 配置多端口监控 | `port = 22,10033`（在 jail.local 中） | 监控 SSH 多端口 |
| 查看所有Jail状态 | `sudo fail2ban-client status` | 显示所有监控服务状态 |
| 测试配置语法 | `fail2ban-client -t` | 验证配置文件语法 |

#### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 查看封禁列表 | `sudo fail2ban-client status sshd` | 显示当前被封禁的 IP |
| 查看日志文件 | `tail -f /var/log/fail2ban.log` | 实时查看fail2ban日志 |

#### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 手动封禁/解封 IP | `sudo fail2ban-client set sshd banip 1.2.3.4`<br>`sudo fail2ban-client set sshd unbanip 1.2.3.4` | 即时生效 |
| 日志路径检查 | `grep -i "fail2ban" /var/log/messages` | 排查封禁行为 |
| 重新加载配置 | `sudo fail2ban-client reload` | 重新加载配置文件 |

### 最佳实践

1. **合理设置封禁时间**：避免误封重要IP，设置合适的bantime
   ```bash
   # 在 /etc/fail2ban/jail.local 中配置
   [sshd]
   enabled = true
   port = 22
   filter = sshd
   logpath = /var/log/auth.log
   maxretry = 3
   bantime = 600    # 封禁10分钟
   findtime = 600   # 在10分钟内失败3次则封禁
   ```

2. **配置白名单**：将可信IP加入白名单避免误封
   ```bash
   # 在 /etc/fail2ban/jail.local 中配置
   [DEFAULT]
   ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24 203.0.113.1
   
   # 重新加载配置
   sudo systemctl reload fail2ban
   ```

3. **监控日志文件**：确保监控的日志文件路径正确且可访问
   ```bash
   # 检查fail2ban状态
   sudo fail2ban-client status
   
   # 检查特定jail的状态
   sudo fail2ban-client status sshd
   
   # 查看fail2ban日志
   tail -f /var/log/fail2ban.log
   ```

## 4. ClamAV 防病毒

### 作用

ClamAV是一个开源的防病毒软件工具包，主要用于邮件网关扫描和终端安全。它包含病毒扫描器、自动更新病毒库工具和多种工具接口，可以检测木马、病毒、恶意软件和其他恶意威胁。

### 部署

ClamAV需要手动安装：

```bash
# 在RHEL/CentOS上安装
sudo yum install clamav clamd clamav-update

# 在Ubuntu/Debian上安装
sudo apt-get install clamav clamav-daemon

# 更新病毒库
sudo freshclam

# 启动并启用ClamAV守护进程
sudo systemctl enable --now clamav-daemon

# 检查ClamAV状态
sudo systemctl status clamav-daemon
```

### 常用命令

#### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 安装与更新 | `sudo dnf install clamav clamd clamav-update`<br>`sudo freshclam` | 安装后需更新病毒库 |
| 更新病毒库 | `freshclam` | 手动更新病毒特征库 |
| 启动守护进程 | `sudo systemctl start clamd` | 启动ClamAV守护进程 |

#### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 扫描目录 | `clamscan -r --bell -i /home` | 递归扫描 /home，发现病毒时告警 |
| 检查病毒库版本 | `clamscan -V` | 显示当前病毒库版本 |

#### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 后台全盘扫描 | `nohup clamscan -r / --log=/var/log/clamav/scan.log &` | 日志保存到指定文件 |
| 定时任务 | `echo "0 3 * * * root /usr/bin/clamscan -r / --log=/var/log/clamav/daily.log" > /etc/cron.d/clamav` | 每天 3 点扫描 |
| 检查守护进程状态 | `systemctl status clamav-daemon` | 检查clamav守护进程状态 |

### 最佳实践

1. **定期更新病毒库**：确保病毒特征库保持最新
   ```bash
   # 手动更新病毒库
   sudo freshclam
   
   # 检查病毒库版本
   clamscan -V
   
   # 配置自动更新（在 /etc/freshclam.conf 中）
   # Checks 24  # 每天检查24次
   ```

2. **安排扫描时间**：将全盘扫描安排在系统负载较低的时间段
   ```bash
   # 创建定时扫描脚本
   cat > /usr/local/bin/clamav-scan.sh << 'EOF'
   #!/bin/bash
   LOGFILE="/var/log/clamav/scan-$(date +%Y-%m-%d).log"
   clamscan -r / --log=$LOGFILE
   EOF
   
   chmod +x /usr/local/bin/clamav-scan.sh
   
   # 添加到crontab（每天凌晨2点执行）
   echo "0 2 * * * /usr/local/bin/clamav-scan.sh" | sudo crontab -
   ```

3. **监控扫描结果**：定期检查扫描日志，及时处理发现的威胁
   ```bash
   # 检查扫描日志中的感染文件
   grep "FOUND" /var/log/clamav/scan-*.log
   
   # 隔离感染文件
   clamscan -r --move=/var/clamav/quarantine /home
   
   # 删除感染文件
   clamscan -r --remove /tmp
   ```

## 5. Chrony NTS 安全时间同步

### 作用

Chrony是一个高精度的时间同步守护进程，用于保持系统时钟与参考时钟同步。NTS（Network Time Security）是用于保护NTP（网络时间协议）通信的安全协议，提供加密认证和隐私保护。

### 部署

Chrony通常在大多数Linux发行版中默认安装。要检查和启用Chrony：

```bash
# 检查Chrony状态
sudo systemctl status chronyd

# 启用并启动Chrony
sudo systemctl enable --now chronyd

# 检查时间同步状态
chronyc tracking
```

如果需要安装Chrony：

```bash
# 在RHEL/CentOS上安装
sudo yum install chrony

# 在Ubuntu/Debian上安装
sudo apt-get install chrony
```

### 常用命令

#### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 生成 NTP 密钥 | `sudo chronyc-keygen > /etc/chrony.keys` | 用于传统密钥认证 |
| 启用 NTS | `ntsenable`<br>`ntsdumpdir /var/lib/chrony`（在 chrony.conf 中） | 需配合 TLS 证书 |
| 证书配置 | `ntscertfile /path/to/cert.pem`<br>`ntskeyfile /path/to/key.pem` | 证书需定期续期（如 Let's Encrypt） |

#### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 验证 NTS 状态 | `chronyc ntsdata`<br>`chronyc tracking` | 检查握手和同步状态 |
| 查看时间源 | `chronyc sources` | 显示时间源信息 |
| 查看时间源状态 | `chronyc sourcestats` | 显示时间源统计信息 |

#### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 强制时间更新 | `chronyc makestep` | 立即同步时间 |
| 查看详细跟踪信息 | `chronyc tracking -v` | 显示详细跟踪信息 |

### 最佳实践

1. **配置多个时间源**：配置至少3个时间源以提高可靠性
   ```bash
   # 在 /etc/chrony.conf 中配置多个时间源
   # 优先使用支持NTS的安全时间源
   server time.cloudflare.com iburst nts
   server time.google.com iburst nts
   server time.facebook.com iburst nts
   
   # 备用传统NTP服务器
   server 0.pool.ntp.org iburst
   server 1.pool.ntp.org iburst
   server 2.pool.ntp.org iburst
   
   # 重新加载配置
   sudo systemctl reload chronyd
   ```

2. **启用NTS加密**：使用NTS加密提高时间同步安全性
   ```bash
   # 检查NTS是否正常工作
   chronyc ntsdata
   
   # 预期输出应显示已建立的NTS关联
   # 示例输出：
   # Hostname: time.cloudflare.com
   # Port: 123
   # Mode: Server
   # NTS-STS-Port: 443
   # NTS-STS-Resource: /nts
   # Fingerprint: SHA256:...
   ```

3. **监控同步状态**：定期检查时间同步状态确保准确性
   ```bash
   # 检查时间同步状态
   chronyc tracking
   
   # 查看时间源信息
   chronyc sources -v
   
   # 查看时间源统计
   chronyc sourcestats
   
   # 设置告警脚本（当时间偏差超过阈值时）
   cat > /usr/local/bin/check-time-sync.sh << 'EOF'
   #!/bin/bash
   OFFSET=$(chronyc tracking | grep "System time" | awk '{print $4}' | sed 's/[\+\-]//')
   if (( $(echo "$OFFSET > 1.0" | bc -l) )); then
       echo "Warning: Time offset is ${OFFSET} seconds" | logger -t time-check
   fi
   EOF
   
   chmod +x /usr/local/bin/check-time-sync.sh
   
   # 添加到crontab（每小时检查一次）
   echo "0 * * * * /usr/local/bin/check-time-sync.sh" | sudo crontab -
   ```

## 6. 服务管理

### 作用

服务管理是Linux系统管理的核心部分，负责启动、停止、重启和监控系统服务。通过systemd等服务管理器，可以确保关键服务在系统启动时自动运行，并在出现故障时自动恢复。

### 部署

Systemd是现代Linux发行版的默认服务管理器，通常预装在系统中。要检查systemd状态：

```bash
# 检查systemd状态
systemctl status

# 查看systemd版本
systemctl --version
```

### 常用命令

#### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 禁用服务 | `sudo systemctl disable --now servicename` | 停止并禁用开机启动 |
| 强制锁定服务 | `sudo systemctl mask servicename` | 防止任何方式启动 |
| 查看服务依赖 | `systemctl list-dependencies servicename` | 显示服务依赖关系 |

#### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 查看服务状态 | `sudo systemctl is-enabled servicename`<br>`sudo systemctl status servicename` | 检查是否禁用成功 |
| 列出所有服务 | `systemctl list-units --type=service` | 列出所有服务单元 |

#### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 重启失败服务 | `systemctl reset-failed servicename` | 重置失败状态后重启 |
| 查看服务日志 | `journalctl -u servicename` | 查看特定服务日志 |
| 实时查看服务日志 | `journalctl -u servicename -f` | 实时查看服务日志 |

### 最佳实践

1. **使用模板单元文件**：对于相似服务，使用模板单元文件提高管理效率
   ```bash
   # 创建模板服务文件
   cat > /etc/systemd/system/app@.service << 'EOF'
   [Unit]
   Description=Application instance %i
   After=network.target
   
   [Service]
   Type=simple
   User=appuser
   ExecStart=/usr/local/bin/app --instance=%i
   Restart=always
   
   [Install]
   WantedBy=multi-user.target
   EOF
   
   # 使用模板启动多个实例
   sudo systemctl enable --now app@1.service
   sudo systemctl enable --now app@2.service
   ```

2. **设置资源限制**：为服务设置合理的内存和CPU限制
   ```bash
   # 为服务添加资源限制
   sudo systemctl edit nginx.service
   
   # 添加以下内容:
   [Service]
   MemoryLimit=512M
   CPUQuota=50%
   LimitNOFILE=65536
   
   # 重新加载并重启服务
   sudo systemctl daemon-reload
   sudo systemctl restart nginx.service
   
   # 验证资源限制
   systemctl show nginx.service | grep -E "Memory|CPU"
   ```

3. **启用日志轮转**：配置日志轮转避免日志文件过大
   ```bash
   # 为服务配置日志轮转
   cat > /etc/logrotate.d/myapp << 'EOF'
   /var/log/myapp/*.log {
       daily
       missingok
       rotate 30
       compress
       delaycompress
       notifempty
       create 644 myapp myapp
   }
   EOF
   
   # 测试配置
   sudo logrotate -d /etc/logrotate.d/myapp
   
   # 手动执行轮转
   sudo logrotate -f /etc/logrotate.d/myapp
   ```

## 7. 补充工具

### 作用

补充工具包括一系列系统管理和监控工具，用于实时监控系统资源使用情况、检查磁盘空间、测试网络连通性等，帮助系统管理员更好地维护和诊断系统问题。

### 部署

大多数补充工具可以通过包管理器安装：

```bash
# 在RHEL/CentOS上安装
sudo yum install htop iotop nethogs

# 在Ubuntu/Debian上安装
sudo apt-get install htop iotop nethogs
```

### 常用命令

#### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 系统资源监控 | `htop`<br>`iotop`<br>`nethogs` | 实时监控系统资源使用情况 |
| 磁盘空间检查 | `df -h`<br>`du -sh /path` | 检查磁盘使用情况 |
| 日志实时监控 | `journalctl -u chronyd -f`<br>`tail -f /var/log/secure` | 跟踪服务日志 |
| 网络连通性测试 | `curl -I http://example.com`<br>`telnet ntp.yourdomain.com 123` | 检查端口和服务响应 |
| 证书有效期检查 | `openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -noout -dates` | 验证 TLS 证书过期时间 |

#### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 系统健康检查 | `top`<br>`free -m`<br>`uptime` | 检查系统整体健康状况 |
| 网络连接检查 | `ss -tulnp`<br>`netstat -tulnp` | 查看网络连接状态 |
| 进程资源使用 | `ps aux --sort=-%mem | head -10` | 查看内存使用最多的进程 |
| CPU信息检查 | `lscpu` | 查看CPU详细信息 |

#### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 实时监控系统 | `watch -n 1 'df -h'` | 实时监控磁盘使用情况 |
| 查找大文件 | `find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10` | 查找系统中的大文件 |
| 检查系统日志 | `journalctl -f` | 实时查看系统日志 |
| 检查硬件信息 | `lshw` | 查看硬件详细信息 |

### 最佳实践

1. **定期监控系统资源**：使用系统监控工具及时发现性能瓶颈
   ```bash
   # 使用htop查看实时进程信息
   htop
   
   # 使用iotop监控磁盘I/O
   sudo iotop -ao
   
   # 使用nethogs监控网络使用情况
   sudo nethogs eth0
   
   # 创建系统健康检查脚本
   cat > /usr/local/bin/system-health-check.sh << 'EOF'
   #!/bin/bash
   echo "=== System Health Check ==="
   echo "CPU Usage:"
   top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
   echo "Memory Usage:"
   free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2 }'
   echo "Disk Usage:"
   df -h / | awk 'NR==2{print $5}'
   echo "Load Average:"
   uptime | awk -F'load average:' '{print $2}'
   EOF
   
   chmod +x /usr/local/bin/system-health-check.sh
   ```

2. **定期检查磁盘空间**：避免因磁盘空间不足导致服务异常
   ```bash
   # 检查磁盘使用情况
   df -h
   
   # 查找大文件
   find / -type f -size +100M -exec ls -lh {} \; 2>/dev/null | head -10
   
   # 查找大目录
   du -sh /* 2>/dev/null | sort -hr | head -10
   
   # 设置磁盘空间告警
   cat > /usr/local/bin/disk-alert.sh << 'EOF'
   #!/bin/bash
   THRESHOLD=80
   USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
   if [ $USAGE -gt $THRESHOLD ]; then
       echo "Warning: Disk usage is ${USAGE}%" | logger -t disk-alert
   fi
   EOF
   
   chmod +x /usr/local/bin/disk-alert.sh
   
   # 添加到crontab（每小时检查一次）
   echo "0 * * * * /usr/local/bin/disk-alert.sh" | sudo crontab -
   ```

3. **定期检查证书有效期**：避免因证书过期导致服务中断
   ```bash
   # 检查单个证书有效期
   openssl x509 -in /etc/letsencrypt/live/example.com/cert.pem -noout -dates
   
   # 批量检查证书有效期
   cat > /usr/local/bin/cert-check.sh << 'EOF'
   #!/bin/bash
   CERT_DIRS="/etc/letsencrypt/live/*"
   for dir in $CERT_DIRS; do
       if [ -d "$dir" ]; then
           DOMAIN=$(basename $dir)
           echo "Checking certificate for $DOMAIN:"
           openssl x509 -in $dir/cert.pem -noout -dates
           echo "---"
       fi
   done
   EOF
   
   chmod +x /usr/local/bin/cert-check.sh
   
   # 设置证书过期告警（每天检查）
   echo "0 9 * * * /usr/local/bin/cert-check.sh" | sudo crontab -
   ```