#!/bin/bash

# 简单的Kafka验证脚本

BOOTSTRAP_SERVER=${1:-localhost:9092}
TOPIC=${2:-test-topic}

echo "测试Kafka连接: $BOOTSTRAP_SERVER"

# 检查Docker是否可用
check_docker() {
    if command -v docker &> /dev/null; then
        if docker info &> /dev/null; then
            print_info "Docker 可用"
            return 0
        else
            print_warning "Docker 已安装但不可用"
        fi
    else
        print_warning "未安装 Docker"
    fi
    return 1
}

# 检查kafka-topics命令是否可用
if command -v kafka-topics &> /dev/null; then
    KAFKA_CMD="kafka-topics"
elif docker ps &> /dev/null; then
    # 尝试使用Docker运行，首先检查是否存在kafka-network
    if docker network ls | grep -q kafka-network; then
        KAFKA_CMD="docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c /usr/bin/kafka-topics"
    else
        # 如果没有kafka-network，则使用默认网络
        KAFKA_CMD="docker run --rm confluentinc/cp-kafka:7.5.0 bash -c /usr/bin/kafka-topics"
    fi
else
    echo "错误: 未找到Kafka命令行工具或Docker"
    exit 1
fi

# 测试连接并列出topics
echo "=== 列出所有Topics ==="
echo "$KAFKA_CMD --bootstrap-server $BOOTSTRAP_SERVER --list"

$KAFKA_CMD --bootstrap-server $BOOTSTRAP_SERVER --list

if [ $? -eq 0 ]; then
    echo "✓ 成功连接到Kafka集群"
else
    echo "✗ 无法连接到Kafka集群"
    exit 1
fi

# 创建测试topic
echo "=== 创建测试Topic ==="
if command -v kafka-topics &> /dev/null; then
    $KAFKA_CMD --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --partitions 1 --replication-factor 1 2>/dev/null || echo "Topic可能已存在"
else
    # 使用Docker创建topic
    if docker network ls | grep -q kafka-network; then
        docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --partitions 1 --replication-factor 1" 2>/dev/null || \
        docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "/usr/bin/kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --partitions 1 --replication-factor 1" 2>/dev/null || \
        echo "Topic可能已存在"
    else
        docker run --rm confluentinc/cp-kafka:7.5.0 bash -c "kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --partitions 1 --replication-factor 1" 2>/dev/null || \
        docker run --rm confluentinc/cp-kafka:7.5.0 bash -c "/usr/bin/kafka-topics --bootstrap-server $BOOTSTRAP_SERVER --create --topic $TOPIC --partitions 1 --replication-factor 1" 2>/dev/null || \
        echo "Topic可能已存在"
    fi
fi

# 测试生产消息
echo "=== 发送测试消息 ==="
if command -v kafka-console-producer &> /dev/null; then
    echo "Hello Kafka from test script" | kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC 2>/dev/null
else
    # 使用Docker发送消息
    if docker network ls | grep -q kafka-network; then
        echo "Hello Kafka from test script" | docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC" 2>/dev/null || \
        echo "Hello Kafka from test script" | docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "/usr/bin/kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC" 2>/dev/null
    else
        echo "Hello Kafka from test script" | docker run --rm confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC" 2>/dev/null || \
        echo "Hello Kafka from test script" | docker run --rm confluentinc/cp-kafka:7.5.0 bash -c "/usr/bin/kafka-console-producer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC" 2>/dev/null
    fi
fi

if [ $? -eq 0 ]; then
    echo "✓ 成功发送消息到Topic: $TOPIC"
else
    echo "✗ 发送消息失败"
fi

# 测试消费消息
echo "=== 消费测试消息 ==="
if command -v timeout &> /dev/null && command -v kafka-console-consumer &> /dev/null; then
    timeout 5 kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC --from-beginning --max-messages 1 2>/dev/null
elif docker ps &> /dev/null; then
    # 使用Docker消费消息
    if docker network ls | grep -q kafka-network; then
        timeout 5 docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC --from-beginning --max-messages 1" 2>/dev/null || \
        timeout 5 docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "/usr/bin/kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC --from-beginning --max-messages 1" 2>/dev/null
    else
        timeout 5 docker run --rm confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC --from-beginning --max-messages 1" 2>/dev/null || \
        timeout 5 docker run --rm confluentinc/cp-kafka:7.5.0 bash -c "/usr/bin/kafka-console-consumer --bootstrap-server $BOOTSTRAP_SERVER --topic $TOPIC --from-beginning --max-messages 1" 2>/dev/null
    fi
else
    echo "✗ 无法执行消息消费测试"
fi

if [ $? -eq 0 ]; then
    echo "✓ 成功从Topic消费消息: $TOPIC"
else
    echo "✗ 消费消息失败或超时"
fi

echo "=== 测试完成 ==="