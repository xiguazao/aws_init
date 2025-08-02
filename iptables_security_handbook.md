# iptables 安全配置手册

## 目录
1. [iptables 作用](#1-iptables-作用)
2. [部署](#2-部署)
3. [常用命令](#3-常用命令)
4. [最佳实践](#4-最佳实践)

## 1. iptables 作用

iptables 是 Linux 系统中最常用的防火墙工具，它工作在网络层，可以对进出系统的网络数据包进行过滤和处理。通过定义规则链，iptables 能够实现以下功能：

- **访问控制**：允许或拒绝特定的网络连接
- **网络地址转换(NAT)**：实现内网与外网的地址转换
- **数据包修改**：修改数据包的内容或头部信息
- **流量监控**：统计网络流量和连接情况
- **防止攻击**：抵御常见的网络攻击，如DDoS、端口扫描等

iptables 基于表（tables）和链（chains）的概念工作：
- **表**：包含不同功能的规则集合，主要有 filter、nat、mangle 和 raw 表
- **链**：预定义的规则检查点，如 INPUT、OUTPUT、FORWARD、PREROUTING、POSTROUTING

## 2. 部署

### 检查 iptables 是否安装

```bash
# 检查 iptables 版本
iptables --version

# 检查 iptables 服务状态
sudo systemctl status iptables

# 检查当前规则
sudo iptables -L -n -v
```

### 安装 iptables

```bash
# 在 RHEL/CentOS 上安装
sudo yum install iptables iptables-services

# 在 Ubuntu/Debian 上安装
sudo apt-get install iptables iptables-persistent
```

### 启用 iptables 服务

```bash
# 启用并启动 iptables 服务
sudo systemctl enable iptables
sudo systemctl start iptables

# 保存当前规则（RHEL/CentOS）
sudo service iptables save

# 保存当前规则（Ubuntu/Debian）
sudo iptables-save > /etc/iptables/rules.v4
```

## 3. 常用命令

### 基础命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 查看规则 | `iptables -L` | 列出所有规则 |
| 查看详细规则 | `iptables -L -n -v` | 以详细格式显示规则 |
| 清空规则 | `iptables -F` | 清空所有规则 |
| 删除自定义链 | `iptables -X` | 删除用户自定义链 |
| 重置计数器 | `iptables -Z` | 将所有规则的包和字节计数器清零 |
| 设置默认策略 | `iptables -P INPUT DROP` | 设置INPUT链默认策略为DROP |

### 状态检查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 查看NAT表规则 | `iptables -t nat -L -n -v` | 查看NAT表规则 |
| 查看规则计数 | `iptables -L -n -v -x` | 显示精确的包和字节计数 |
| 查看规则行号 | `iptables -L --line-numbers` | 显示规则的行号 |
| 实时监控 | `watch -n 1 'iptables -L -n -v'` | 实时监控规则匹配情况 |

### 故障排查命令

| 功能 | 命令 | 说明 |
|------|------|------|
| 添加日志规则 | `iptables -A INPUT -j LOG --log-prefix "INPUT: "` | 为匹配的数据包添加日志 |
| 插入规则 | `iptables -I INPUT 1 -s 192.168.1.100 -j ACCEPT` | 在指定位置插入规则 |
| 删除规则 | `iptables -D INPUT -s 192.168.1.100 -j ACCEPT` | 删除指定规则 |
| 删除指定行号规则 | `iptables -D INPUT 3` | 删除INPUT链第3条规则 |

### 常见规则示例

```bash
# 允许本地回环接口
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许SSH连接（端口22）
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# 允许HTTP连接（端口80）
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 允许HTTPS连接（端口443）
iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# 允许ICMP（ping）
iptables -A INPUT -p icmp -j ACCEPT

# 限制SSH连接速率（防止暴力破解）
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --set
iptables -A INPUT -p tcp --dport 22 -m state --state NEW -m recent --update --seconds 60 --hitcount 4 -j DROP

# 限制连接数（防止DDoS）
iptables -A INPUT -p tcp --dport 80 -m limit --limit 25/minute --limit-burst 100 -j ACCEPT

# NAT转发（将内网80端口转发到外网）
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.1.100:80
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

## 4. 最佳实践

### 1. 制定安全策略

在配置iptables规则前，应先制定明确的安全策略：

```bash
# 设置默认策略为DROP（更安全）
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# 允许本地回环接口
iptables -A INPUT -i lo -j ACCEPT

# 允许已建立的连接
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 允许特定服务（根据实际需要添加）
iptables -A INPUT -p tcp --dport 22 -j ACCEPT   # SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT   # HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # HTTPS
```

### 2. 使用自定义链组织规则

使用自定义链可以更好地组织和管理规则：

```bash
# 创建自定义链
iptables -N TCP
iptables -N UDP

# 将TCP和UDP流量分别跳转到自定义链
iptables -A INPUT -p tcp -j TCP
iptables -A INPUT -p udp -j UDP

# 在自定义链中添加规则
iptables -A TCP -p tcp --dport 22 -j ACCEPT
iptables -A TCP -p tcp --dport 80 -j ACCEPT
iptables -A TCP -p tcp --dport 443 -j ACCEPT
iptables -A UDP -p udp --dport 53 -j ACCEPT

# 丢弃无效数据包
iptables -A INPUT -m state --state INVALID -j DROP
```

### 3. 实施速率限制防止攻击

通过限制连接速率来防止暴力破解和DDoS攻击：

```bash
# 创建自定义链用于速率限制
iptables -N RATE_LIMIT

# 对SSH连接实施速率限制
iptables -A RATE_LIMIT -p tcp --dport 22 -m recent --name ssh --set
iptables -A RATE_LIMIT -p tcp --dport 22 -m recent --name ssh --update --seconds 60 --hitcount 4 -j LOG --log-prefix "SSH brute force: "
iptables -A RATE_LIMIT -p tcp --dport 22 -m recent --name ssh --update --seconds 60 --hitcount 4 -j DROP
iptables -A RATE_LIMIT -p tcp --dport 22 -j ACCEPT

# 跳转到速率限制链
iptables -I INPUT -p tcp --dport 22 -j RATE_LIMIT
```

### 4. 记录和监控网络活动

通过日志记录可疑活动并监控网络流量：

```bash
# 记录被拒绝的连接
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables denied: " --log-level 7

# 记录特定端口的访问
iptables -A INPUT -p tcp --dport 22 -m limit --limit 3/min -j LOG --log-prefix "SSH access: "

# 使用watch命令实时监控规则匹配情况
# watch -n 1 'iptables -L -n -v'
```

### 5. 定期备份和恢复规则

定期备份iptables规则以防止意外丢失：

```bash
# 备份规则
sudo iptables-save > /etc/iptables/backup_$(date +%Y%m%d).rules

# 恢复规则
sudo iptables-restore < /etc/iptables/backup_20231201.rules

# 创建自动备份脚本
cat > /usr/local/bin/iptables-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/etc/iptables/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份规则
iptables-save > $BACKUP_DIR/iptables_$DATE.rules

# 保留最近7天的备份
find $BACKUP_DIR -name "iptables_*.rules" -mtime +7 -delete
EOF

chmod +x /usr/local/bin/iptables-backup.sh

# 添加到crontab（每天凌晨2点执行）
echo "0 2 * * * /usr/local/bin/iptables-backup.sh" | sudo crontab -
```

### 6. 防止IP欺骗

通过限制特定网络接口的IP地址范围来防止IP欺骗：

```bash
# 防止来自外部接口的私有IP地址
iptables -A INPUT -i eth0 -s 10.0.0.0/8 -j DROP
iptables -A INPUT -i eth0 -s 172.16.0.0/12 -j DROP
iptables -A INPUT -i eth0 -s 192.168.0.0/16 -j DROP
iptables -A INPUT -i eth0 -s 127.0.0.0/8 -j DROP

# 防止来自内部接口的公网IP地址（根据实际网络配置调整）
# iptables -A INPUT -i eth1 -s 1.1.1.0/24 -j DROP
```

### 7. 优化规则顺序

将最常用的规则放在前面，提高处理效率：

```bash
# 错误示例：将不常用的规则放在前面
iptables -A INPUT -p tcp --dport 8080 -j DROP
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 正确示例：将常用的规则放在前面
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 8080 -j DROP
```

### 8. 使用模块扩展功能

利用iptables模块提供更多功能：

```bash
# 使用limit模块限制日志记录速率
iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables: "

# 使用connlimit模块限制每个IP的连接数
iptables -A INPUT -p tcp --dport 22 -m connlimit --connlimit-above 3 -j REJECT

# 使用time模块在特定时间允许访问
iptables -A INPUT -p tcp --dport 22 -m time --timestart 09:00 --timestop 18:00 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -j DROP

# 使用string模块匹配数据包内容
iptables -A FORWARD -m string --string "blocked_content" --algo bm -j DROP
```

通过遵循这些最佳实践，您可以构建一个既安全又高效的防火墙配置，有效保护您的系统免受网络威胁。