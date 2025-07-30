#!/bin/bash

# 简单的Kafka验证脚本

BOOTSTRAP_SERVER=${1:-localhost:9092}
TOPIC=${2:-test-topic}

echo "测试Kafka连接: $BOOTSTRAP_SERVER"

# 检查kafka-topics命令是否可用
if command -v kafka-topics &> /dev/null; then
    KAFKA_CMD="kafka-topics"
elif docker ps &> /dev/null; then
    # 尝试使用Docker运行，并与Kafka容器在同一网络
    KAFKA_CMD="docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c kafka-topics"
else
    echo "错误: 未找到Kafka命令行工具或Docker"
    exit 1
fi

# 测试连接并列出topics
echo "=== 列出所有Topics ==="
$KAFKA_CMD --bootstrap-server $BOOTSTRAP_SERVER --list

if [ $? -eq 0 ]; then
    echo "✓ 成功连接到Kafka集群"
else
    echo "✗ 无法连接到Kafka集群"
    exit 1
fi

# 创建测试topic
echo "=== 创建测试Topic ==="
$KAFKA_CMD --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --partitions 1 --replication-factor 1 2>/dev/null || echo "Topic可能已存在"

# 测试生产消息
echo "=== 发送测试消息 ==="
echo "Hello Kafka from test script" | docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ 成功发送消息到Topic: $TOPIC"
else
    echo "✗ 发送消息失败"
fi

# 测试消费消息
echo "=== 消费测试消息 ==="
timeout 5 docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC --from-beginning --max-messages 1" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ 成功从Topic消费消息: $TOPIC"
else
    echo "✗ 消费消息失败或超时"
fi

echo "=== 测试完成 ==="