# Kafka跨节点集群部署

这个目录包含了用于在多个物理节点上部署Kafka集群的配置文件。

## 架构

提供了两种跨节点部署方式：
1. ZooKeeper模式：每个节点运行一个ZooKeeper实例和一个Kafka Broker
2. KRaft模式：每个节点运行一个Kafka Broker（同时充当Controller角色）

## 目录结构

```
multi-node/
├── zookeeper-mode/      # ZooKeeper模式配置
│   ├── node1/           # 节点1配置
│   │   ├── docker-compose.yml
│   │   └── zookeeper/
│   │       └── data/
│   ├── node2/           # 节点2配置
│   │   ├── docker-compose.yml
│   │   └── zookeeper/
│   │       └── data/
│   └── node3/           # 节点3配置
│       ├── docker-compose.yml
│       └── zookeeper/
│           └── data/
├── kraft-mode/          # KRaft模式配置
│   ├── node1/           # 节点1配置
│   │   └── docker-compose.yml
│   ├── node2/           # 节点2配置
│   │   └── docker-compose.yml
│   └── node3/           # 节点3配置
│       └── docker-compose.yml
├── kafka-manager/       # Kafka Manager配置
│   ├── docker-compose.yml       # 用于ZooKeeper模式
│   └── docker-compose-kraft.yml # 用于KRaft模式
└── README.md            # 说明文档
```

## 部署前准备

### 系统要求
1. 每个节点都需要安装Docker和Docker Compose
2. 确保节点间网络互通
3. 开放必要的端口：
   - ZooKeeper: 2181, 2888, 3888
   - Kafka: 9092, 9093, 19092
   - Kafka Manager: 9000

### 系统配置
在每个节点上执行以下操作：

1. 增加系统限制：
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```

2. 将配置添加到`/etc/sysctl.conf`以持久化：
   ```bash
   echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
   ```

3. 确保防火墙允许以下端口通信：
   ```bash
   # ZooKeeper内部通信端口
   sudo ufw allow 2888
   sudo ufw allow 3888
   
   # ZooKeeper客户端端口
   sudo ufw allow 2181
   
   # Kafka内部通信端口
   sudo ufw allow 9092
   
   # Kafka控制器端口 (KRaft模式)
   sudo ufw allow 9093
   
   # Kafka外部访问端口
   sudo ufw allow 19092
   
   # Kafka Manager端口
   sudo ufw allow 9000
   ```

## 跨节点部署步骤

### ZooKeeper模式

#### 1. 配置节点
在每个节点上创建相应的目录结构并复制配置文件：

**节点1 (IP: 10.0.1.10)**
```bash
mkdir -p ~/kafka-deployment/zookeeper/data
# 将 zookeeper-mode/node1/docker-compose.yml 复制到 ~/kafka-deployment/
```

**节点2 (IP: 10.0.1.11)**
```bash
mkdir -p ~/kafka-deployment/zookeeper/data
# 将 zookeeper-mode/node2/docker-compose.yml 复制到 ~/kafka-deployment/
```

**节点3 (IP: 10.0.1.12)**
```bash
mkdir -p ~/kafka-deployment/zookeeper/data
# 将 zookeeper-mode/node3/docker-compose.yml 复制到 ~/kafka-deployment/
```

#### 2. 设置ZooKeeper节点ID
在每个节点上设置唯一的ZooKeeper节点ID：

**节点1**
```bash
echo "1" > ~/kafka-deployment/zookeeper/data/myid
```

**节点2**
```bash
echo "2" > ~/kafka-deployment/zookeeper/data/myid
```

**节点3**
```bash
echo "3" > ~/kafka-deployment/zookeeper/data/myid
```

#### 3. 部署ZooKeeper集群
在每个节点上启动ZooKeeper服务：

**所有节点**
```bash
cd ~/kafka-deployment
# 检查并根据实际IP地址修改docker-compose.yml配置
docker-compose up -d
```

等待所有ZooKeeper节点启动并形成集群（大约1-2分钟）。

#### 4. 验证ZooKeeper集群状态
在任意节点上执行以下命令验证集群状态：

```bash
docker exec zookeeper-node1 zookeeper-shell 10.0.1.10:2181 ls /
```

### KRaft模式

#### 1. 生成集群ID
KRaft模式要求集群ID必须是有效的16字节UUID（通常为base64编码格式）。在任意节点上生成集群ID：

```bash
docker run --rm confluentinc/cp-kafka:7.5.0 kafka-storage random-uuid
```

将生成的UUID替换所有docker-compose.yml文件中的`CLUSTER_ID`值。

示例生成的UUID格式：
```
ciThbX9QTi6aK1rW8rHO9w==
```

#### 2. 配置节点
在每个节点上创建相应的目录结构并复制配置文件：

**节点1 (IP: 10.0.1.10)**
```bash
mkdir -p ~/kafka-deployment
# 将 kraft-mode/node1/docker-compose.yml 复制到 ~/kafka-deployment/
```

**节点2 (IP: 10.0.1.11)**
```bash
mkdir -p ~/kafka-deployment
# 将 kraft-mode/node2/docker-compose.yml 复制到 ~/kafka-deployment/
```

**节点3 (IP: 10.0.1.12)**
```bash
mkdir -p ~/kafka-deployment
# 将 kraft-mode/node3/docker-compose.yml 复制到 ~/kafka-deployment/
```

#### 3. 格式化存储目录
在每个节点上格式化Kafka存储目录：

**所有节点**
```bash
cd ~/kafka-deployment
# 注意：将 <cluster-id> 替换为实际生成的集群ID
docker-compose run --rm kafka kafka-storage format -t <cluster-id> -c /etc/kafka/kafka.properties
```

#### 4. 启动Kafka集群
在每个节点上启动Kafka服务：

**所有节点**
```bash
docker-compose up -d
```

## 配置文件说明

### ZooKeeper模式配置参数

每个节点的配置需要根据实际情况调整以下参数：

1. `ZOOKEEPER_SERVER_ID`: 每个节点的唯一ID (1, 2, 3)
2. `ZOOKEEPER_SERVERS`: 所有ZooKeeper节点的地址信息
3. `KAFKA_BROKER_ID`: Kafka Broker的唯一ID (1, 2, 3)
4. `KAFKA_ZOOKEEPER_CONNECT`: 所有ZooKeeper节点的连接信息
5. `KAFKA_ADVERTISED_LISTENERS`: 节点的对外暴露地址
6. `KAFKA_JMX_HOSTNAME`: 节点的主机名或IP地址
7. 网络配置和端口映射

### KRaft模式配置参数

每个节点的配置需要根据实际情况调整以下参数：

1. `KAFKA_NODE_ID`: 每个节点的唯一ID (1, 2, 3)
2. `KAFKA_CONTROLLER_QUORUM_VOTERS`: 所有Controller节点的信息
3. `KAFKA_ADVERTISED_LISTENERS`: 节点的对外暴露地址
4. `CLUSTER_ID`: 整个集群的唯一标识（需要统一，且必须是有效的16字节UUID）
5. `KAFKA_JMX_HOSTNAME`: 节点的主机名或IP地址
6. 网络配置和端口映射

## 简单访问验证

您可以使用项目根目录中的验证脚本来测试跨节点部署的Kafka集群：

### 使用simple-test.sh快速验证
```bash
# 验证节点1上的Kafka
../simple-test.sh 10.0.1.10:9092

# 验证节点2上的Kafka
../simple-test.sh 10.0.1.11:9092

# 指定自定义topic
../simple-test.sh 10.0.1.10:9092 my-cluster-test
```

### 使用test-kafka.sh完整验证
```bash
# 显示帮助信息
../test-kafka.sh --help

# 测试节点1
../test-kafka.sh -b 10.0.1.10:9092

# 完整测试配置
../test-kafka.sh -b 10.0.1.10:9092 -t cluster-test -m "Hello Multi-node Kafka" -n 3
```

## 管理和监控

### Kafka Manager部署
Kafka Manager可以部署在任意一个节点或单独的管理节点上：

**对于ZooKeeper模式：**
```bash
# 将 kafka-manager/docker-compose.yml 复制到部署目录
cd ~/kafka-manager
# 检查并修改ZK_HOSTS配置以匹配实际的ZooKeeper地址
docker-compose up -d
```

**对于KRaft模式：**
```bash
# 将 kafka-manager/docker-compose-kraft.yml 复制到部署目录
cd ~/kafka-manager
# 检查并修改ZK_HOSTS配置以匹配实际的Kafka地址
docker-compose -f docker-compose-kraft.yml up -d
```

访问地址：http://<manager-node-ip>:9000

### 常用管理命令

进入Kafka容器执行管理命令：
```bash
docker exec -it kafka-broker-1 bash  # ZooKeeper模式
docker exec -it kafka-node-1 bash    # KRaft模式
```

创建Topic：
```bash
# ZooKeeper模式
kafka-topics --create --topic my-topic --bootstrap-server 10.0.1.10:9092 --partitions 3 --replication-factor 3

# KRaft模式
kafka-topics --create --topic my-topic --bootstrap-server 10.0.1.10:9092 --partitions 3 --replication-factor 3
```

查看Topic列表：
```bash
kafka-topics --list --bootstrap-server 10.0.1.10:9092
```

查看集群状态：
```bash
kafka-broker-api-versions --bootstrap-server 10.0.1.10:9092
```

查看集群元数据：
```bash
kafka-metadata-shell --bootstrap-server 10.0.1.10:9092
```

## 故障处理

### 节点故障
如果某个节点发生故障：

1. 检查Docker容器状态：
   ```bash
   docker-compose ps
   ```

2. 查看日志：
   ```bash
   docker-compose logs
   ```

3. 重启服务：
   ```bash
   docker-compose restart
   ```

### 数据恢复
如果需要恢复数据：

1. 停止相关服务
2. 从备份中恢复数据卷
3. 重新启动服务

### 集群扩展
要添加新节点到现有集群：

1. 对于ZooKeeper模式：
   - 需要重新配置所有节点的ZooKeeper设置
   - 通常建议保持奇数个节点（3、5、7等）

2. 对于KRaft模式：
   - 添加新的Broker节点相对简单
   - 更新Controller选举配置

## 性能优化

1. 根据硬件配置调整JVM参数：
   ```yaml
   environment:
     KAFKA_HEAP_OPTS: -Xmx4g -Xms4g
   ```

2. 优化磁盘IO配置：
   ```yaml
   volumes:
     - /path/to/fast/disk/kafka-data:/var/lib/kafka/data
   ```

3. 调整Kafka日志段大小和保留策略：
   ```yaml
   environment:
     KAFKA_LOG_SEGMENT_BYTES: 1073741824  # 1GB
     KAFKA_LOG_RETENTION_HOURS: 168       # 7天
   ```

4. 配置合适的副本因子和分区数：
   - 副本因子通常设置为3
   - 分区数根据预期吞吐量调整

5. 网络优化：
   - 使用高性能网络
   - 调整网络缓冲区大小

## 安全配置

### 启用SSL加密
在生产环境中，应启用SSL加密：

```yaml
environment:
  KAFKA_SSL_KEYSTORE_LOCATION: /path/to/keystore.jks
  KAFKA_SSL_KEYSTORE_PASSWORD: changeit
  KAFKA_SSL_KEY_PASSWORD: changeit
  KAFKA_SSL_TRUSTSTORE_LOCATION: /path/to/truststore.jks
  KAFKA_SSL_TRUSTSTORE_PASSWORD: changeit
```

### 启用SASL认证
启用SASL认证以控制访问：

```yaml
environment:
  KAFKA_SASL_ENABLED_MECHANISMS: PLAIN
  KAFKA_SASL_MECHANISM_INTER_BROKER_PROTOCOL: PLAIN
```

## 备份和恢复

### 定期备份策略
1. 定期备份ZooKeeper数据（ZooKeeper模式）
2. 定期备份Kafka数据目录
3. 备份配置文件和脚本

### 使用Kafka内置工具
使用Kafka提供的工具进行数据导出/导入：
```bash
# 导出数据
kafka-dump-log --print-data-log --files /path/to/log/file

# 导入数据
kafka-replay-log-producer --broker-list 10.0.1.10:9092 --input-file /path/to/input
```

## 监控和告警

### 使用JMX监控
Kafka通过JMX暴露大量指标，可以使用以下工具监控：

1. JConsole
2. Prometheus + Grafana
3. Datadog
4. New Relic

### 关键监控指标
1. Broker级别的指标
2. Topic级别的指标
3. 分区级别的指标
4. 消费者组指标
5. JVM指标

### 日志管理
配置适当的日志轮转策略：
```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```