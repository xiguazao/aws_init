# Kafka集群部署

这个目录包含了使用Docker Compose部署Kafka集群的配置文件。

## 架构

提供了多种部署方式：
1. 完整版（ZooKeeper）：包含3个ZooKeeper节点、3个Kafka Broker节点和1个Kafka Manager
2. 简化版（ZooKeeper）：包含1个ZooKeeper节点和1个Kafka Broker节点
3. 完整版（KRaft）：包含3个Kafka Broker节点（使用KRaft模式，无需ZooKeeper）和1个Kafka Manager
4. 简化版（KRaft）：包含1个Kafka Broker节点（使用KRaft模式，无需ZooKeeper）

## 目录结构

```
kafka/
├── docker-compose.yml              # 完整版ZooKeeper模式Docker Compose配置文件
├── docker-compose-simple.yml       # 简化版ZooKeeper模式Docker Compose配置文件
├── docker-compose-kraft.yml        # 完整版KRaft模式Docker Compose配置文件
├── docker-compose-kraft-simple.yml # 简化版KRaft模式Docker Compose配置文件
├── simple-test.sh                  # 简单验证脚本
├── test-kafka.sh                   # 完整验证脚本
├── README.md                       # 说明文档
└── kafka-manager-env               # Kafka Manager环境变量文件
```

## 部署步骤

### 完整版ZooKeeper模式集群
1. 确保已安装Docker和Docker Compose
2. 在当前目录下运行以下命令启动集群：
   ```bash
   docker-compose up -d
   ```
3. 等待所有服务启动完成（可能需要几分钟时间）
4. 验证服务状态：
   ```bash
   docker-compose ps
   ```

### 简化版ZooKeeper模式集群
1. 确保已安装Docker和Docker Compose
2. 在当前目录下运行以下命令启动集群：
   ```bash
   docker-compose -f docker-compose-simple.yml up -d
   ```
3. 等待服务启动完成
4. 验证服务状态：
   ```bash
   docker-compose -f docker-compose-simple.yml ps
   ```

### 完整版KRaft模式集群（无需ZooKeeper）
1. 确保已安装Docker和Docker Compose
2. KRaft模式要求集群ID必须是有效的16字节UUID（通常为base64编码格式），首先生成集群ID：
   ```bash
   docker run --rm confluentinc/cp-kafka:7.5.0 kafka-storage random-uuid
   ```
3. 将生成的UUID替换[docker-compose-kraft.yml](file:///home/melon/aws_init/services/kafka/docker-compose-kraft.yml)文件中的`CLUSTER_ID`值
4. 在当前目录下运行以下命令启动集群：
   ```bash
   docker-compose -f docker-compose-kraft.yml up -d
   ```
5. 等待所有服务启动完成（可能需要几分钟时间）
6. 验证服务状态：
   ```bash
   docker-compose -f docker-compose-kraft.yml ps
   ```

### 简化版KRaft模式集群（无需ZooKeeper）
1. 确保已安装Docker和Docker Compose
2. KRaft模式要求集群ID必须是有效的16字节UUID（通常为base64编码格式），首先生成集群ID：
   ```bash
   docker run --rm confluentinc/cp-kafka:7.5.0 kafka-storage random-uuid
   ```
3. 将生成的UUID替换[docker-compose-kraft-simple.yml](file:///home/melon/aws_init/services/kafka/docker-compose-kraft-simple.yml)文件中的`CLUSTER_ID`值
4. 在当前目录下运行以下命令启动集群：
   ```bash
   docker-compose -f docker-compose-kraft-simple.yml up -d
   ```
5. 等待服务启动完成
6. 验证服务状态：
   ```bash
   docker-compose -f docker-compose-kraft-simple.yml ps
   ```

## 访问服务

### ZooKeeper模式
- Kafka Brokers: 
  - broker-1: localhost:9092
  - broker-2: localhost:9093
  - broker-3: localhost:9094
- Kafka Manager: http://localhost:9000

### KRaft模式
- Kafka Brokers: 
  - broker-1: localhost:9092
  - broker-2: localhost:9093
  - broker-3: localhost:9094
- Kafka Manager: http://localhost:9000

### 简化版
- Kafka: localhost:9092

## 简单访问验证

项目提供了两个验证脚本：

### 使用simple-test.sh快速验证
```bash
# 验证本地Kafka
./simple-test.sh

# 验证远程Kafka
./simple-test.sh 10.0.1.10:9092

# 指定自定义topic
./simple-test.sh localhost:9092 my-test-topic
```

### 使用test-kafka.sh完整验证
```bash
# 显示帮助信息
./test-kafka.sh --help

# 使用默认配置进行测试
./test-kafka.sh

# 指定bootstrap server
./test-kafka.sh -b 10.0.1.10:9092

# 完整测试配置
./test-kafka.sh -b 10.0.1.10:9092 -t test-topic -m "Hello Kafka" -n 5
```

## 管理Kafka集群

### 使用Kafka Manager
1. 打开浏览器访问 http://localhost:9000
2. 添加集群：
   - 对于ZooKeeper模式：
     - Cluster Name: kafka-cluster
     - Cluster Zookeeper Hosts: zookeeper-1:2181,zookeeper-2:2181,zookeeper-3:2181 (完整版)
     - Cluster Zookeeper Hosts: zookeeper:2181 (简化版)
     - Kafka Version: 3.5.0 (或根据实际版本调整)
   - 对于KRaft模式：
     - Cluster Name: kafka-cluster-kraft
     - Cluster Zookeeper Hosts: kafka-broker-1:9092,kafka-broker-2:9092,kafka-broker-3:9092
     - Kafka Version: 3.5.0 (或根据实际版本调整)

### 使用命令行工具
进入Kafka容器执行命令：
```bash
# ZooKeeper模式完整版
docker exec -it kafka-broker-1 bash

# ZooKeeper模式简化版
docker exec -it kafka bash

# KRaft模式完整版
docker exec -it kafka-broker-1 bash

# KRaft模式简化版
docker exec -it kafka bash
```

创建Topic示例：
```bash
kafka-topics.sh --create --topic test-topic --bootstrap-server kafka-broker-1:9092 --partitions 3 --replication-factor 2

# 简化版
kafka-topics.sh --create --topic test-topic --bootstrap-server localhost:9092 --partitions 1 --replication-factor 1
```

列出所有Topic：
```bash
kafka-topics.sh --list --bootstrap-server kafka-broker-1:9092

# 简化版
kafka-topics.sh --list --bootstrap-server localhost:9092
```

生产消息示例：
```bash
echo "Hello Kafka" | kafka-console-producer.sh --topic test-topic --bootstrap-server kafka-broker-1:9092

# 简化版
echo "Hello Kafka" | kafka-console-producer.sh --topic test-topic --bootstrap-server localhost:9092
```

消费消息示例：
```bash
kafka-console-consumer.sh --topic test-topic --from-beginning --bootstrap-server kafka-broker-1:9092

# 简化版
kafka-console-consumer.sh --topic test-topic --from-beginning --bootstrap-server localhost:9092
```

## 停止和清理

### ZooKeeper模式完整版
停止所有服务：
```bash
docker-compose down
```

停止并删除所有数据卷：
```bash
docker-compose down -v
```

### ZooKeeper模式简化版
停止所有服务：
```bash
docker-compose -f docker-compose-simple.yml down
```

停止并删除所有数据卷：
```bash
docker-compose -f docker-compose-simple.yml down -v
```

### KRaft模式完整版
停止所有服务：
```bash
docker-compose -f docker-compose-kraft.yml down
```

停止并删除所有数据卷：
```bash
docker-compose -f docker-compose-kraft.yml down -v
```

### KRaft模式简化版
停止所有服务：
```bash
docker-compose -f docker-compose-kraft-simple.yml down
```

停止并删除所有数据卷：
```bash
docker-compose -f docker-compose-kraft-simple.yml down -v
```

## 故障排除

### 查看日志
```bash
# ZooKeeper模式完整版 - 查看特定服务日志
docker-compose logs kafka-broker-1

# ZooKeeper模式简化版 - 查看Kafka日志
docker-compose -f docker-compose-simple.yml logs kafka

# KRaft模式完整版 - 查看特定服务日志
docker-compose -f docker-compose-kraft.yml logs kafka-broker-1

# KRaft模式简化版 - 查看Kafka日志
docker-compose -f docker-compose-kraft-simple.yml logs kafka

# 实时查看日志
docker-compose logs -f kafka-broker-1
```

### 常见问题
1. 如果Kafka Manager无法连接到集群，请确保Kafka服务已完全启动
2. 如果遇到网络问题，请检查Docker网络配置
3. 如果端口冲突，请修改docker-compose.yml中的端口映射
4. 对于简化版，注意replication-factor必须小于等于broker数量
5. KRaft模式是较新的功能，在生产环境中使用前请充分测试
6. KRaft模式要求集群ID必须是有效的16字节UUID（通常为base64编码格式）