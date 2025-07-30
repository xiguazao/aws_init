#!/bin/bash

# Kafka 简单访问验证脚本
# 用于测试Kafka集群的连接和基本功能

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认配置
DEFAULT_BOOTSTRAP_SERVER="localhost:9092"
DEFAULT_TOPIC="test-topic"
DEFAULT_MESSAGE="Hello Kafka!"
DEFAULT_NUM_MESSAGES=3

# 打印使用说明
print_usage() {
    echo "Kafka 访问验证脚本"
    echo ""
    echo "使用方法:"
    echo "  $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -b, --bootstrap-server SERVER  Kafka bootstrap server (默认: $DEFAULT_BOOTSTRAP_SERVER)"
    echo "  -t, --topic TOPIC             测试Topic名称 (默认: $DEFAULT_TOPIC)"
    echo "  -m, --message MESSAGE         发送的测试消息 (默认: $DEFAULT_MESSAGE)"
    echo "  -n, --num-messages NUM        发送消息数量 (默认: $DEFAULT_NUM_MESSAGES)"
    echo "  -h, --help                    显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0"
    echo "  $0 -b 10.0.1.10:9092"
    echo "  $0 -t my-test-topic -n 5"
    echo "  $0 -b 10.0.1.10:9092 -t test -m \"Hello Cluster\" -n 10"
}

# 打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "未找到命令: $1"
        return 1
    fi
    return 0
}

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

# 检查Kafka命令行工具是否可用
check_kafka_tools() {
    # 尝试直接使用kafka命令
    if check_command "kafka-topics"; then
        print_info "Kafka 命令行工具可用"
        return 0
    fi
    
    # 尝试通过Docker使用kafka命令
    if check_docker; then
        print_info "将通过Docker使用Kafka命令行工具"
        return 0
    fi
    
    print_error "未找到Kafka命令行工具，也未安装Docker"
    return 1
}

# 通过Docker运行Kafka命令，使用与Kafka容器相同的网络
docker_kafka_command() {
    local cmd=$1
    shift
    local args="$@"
    
    if check_docker; then
        # 尝试找到运行中的Kafka容器
        local kafka_containers=$(docker ps -q -f name=kafka)
        local kafka_container=""
        
        # 获取第一个容器（如果有多个）
        for container in $kafka_containers; do
            kafka_container=$container
            break
        done
        
        if [ -n "$kafka_container" ]; then
            print_info "在容器 $kafka_container 中执行: $cmd $args"
            docker exec $kafka_container bash -c "$cmd $args"
            return $?
        else
            print_warning "未找到运行中的Kafka容器，使用临时容器并连接到kafka-network网络"
            docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "$cmd $args"
            return $?
        fi
    else
        print_error "Docker不可用"
        return 1
    fi
}

# 运行Kafka命令
run_kafka_command() {
    local cmd=$1
    shift
    local args=("$@")
    
    # 直接尝试运行命令
    if command -v $cmd &> /dev/null; then
        print_info "执行: $cmd ${args[@]}"
        "$cmd" "${args[@]}"
        return $?
    else
        # 通过Docker运行命令
        docker_kafka_command "$cmd" "${args[@]}"
        return $?
    fi
}

# 测试连接到Kafka集群
test_connection() {
    local bootstrap_server=$1
    
    print_info "测试连接到Kafka集群: $bootstrap_server"
    
    if command -v kafka-broker-api-versions &> /dev/null; then
        print_info "执行: kafka-broker-api-versions --bootstrap-server $bootstrap_server"
        kafka-broker-api-versions --bootstrap-server $bootstrap_server
    elif check_docker; then
        # 尝试找到运行中的Kafka容器
        local kafka_containers=$(docker ps -q -f name=kafka)
        local kafka_container=""
        
        # 获取第一个容器（如果有多个）
        for container in $kafka_containers; do
            kafka_container=$container
            break
        done
        
        if [ -n "$kafka_container" ]; then
            print_info "在容器 $kafka_container 中执行: kafka-broker-api-versions --bootstrap-server $bootstrap_server"
            docker exec $kafka_container bash -c "kafka-broker-api-versions --bootstrap-server $bootstrap_server"
        else
            print_info "使用临时容器执行: kafka-broker-api-versions --bootstrap-server $bootstrap_server"
            docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-broker-api-versions --bootstrap-server $bootstrap_server"
        fi
    else
        print_error "无法执行kafka-broker-api-versions命令"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        print_success "成功连接到Kafka集群"
        return 0
    else
        print_error "无法连接到Kafka集群"
        return 1
    fi
}

# 创建测试Topic
create_test_topic() {
    local bootstrap_server=$1
    local topic=$2
    local partitions=${3:-3}
    local replication_factor=${4:-1}
    
    print_info "创建测试Topic: $topic"
    
    # 首先检查Topic是否已存在
    if command -v kafka-topics &> /dev/null; then
        if kafka-topics --bootstrap-server $bootstrap_server --list | grep -q "^${topic}$"; then
            print_info "Topic $topic 已存在"
            return 0
        fi
    elif check_docker; then
        # 尝试找到运行中的Kafka容器
        local kafka_containers=$(docker ps -q -f name=kafka)
        local kafka_container=""
        
        # 获取第一个容器（如果有多个）
        for container in $kafka_containers; do
            kafka_container=$container
            break
        done
        
        if [ -n "$kafka_container" ]; then
            if docker exec $kafka_container bash -c "kafka-topics --bootstrap-server $bootstrap_server --list" | grep -q "^${topic}$"; then
                print_info "Topic $topic 已存在"
                return 0
            fi
        else
            if docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-topics --bootstrap-server $bootstrap_server --list" | grep -q "^${topic}$"; then
                print_info "Topic $topic 已存在"
                return 0
            fi
        fi
    else
        print_error "无法执行kafka-topics命令"
        return 1
    fi
    
    # 创建Topic
    if command -v kafka-topics &> /dev/null; then
        print_info "执行: kafka-topics --bootstrap-server $bootstrap_server --create --topic $topic --partitions $partitions --replication-factor $replication_factor"
        kafka-topics --bootstrap-server $bootstrap_server --create --topic $topic --partitions $partitions --replication-factor $replication_factor
    elif check_docker; then
        # 尝试找到运行中的Kafka容器
        local kafka_containers=$(docker ps -q -f name=kafka)
        local kafka_container=""
        
        # 获取第一个容器（如果有多个）
        for container in $kafka_containers; do
            kafka_container=$container
            break
        done
        
        if [ -n "$kafka_container" ]; then
            print_info "在容器 $kafka_container 中执行: kafka-topics --bootstrap-server $bootstrap_server --create --topic $topic --partitions $partitions --replication-factor $replication_factor"
            docker exec $kafka_container bash -c "kafka-topics --bootstrap-server $bootstrap_server --create --topic $topic --partitions $partitions --replication-factor $replication_factor"
        else
            print_info "使用临时容器执行: kafka-topics --bootstrap-server $bootstrap_server --create --topic $topic --partitions $partitions --replication-factor $replication_factor"
            docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-topics --bootstrap-server $bootstrap_server --create --topic $topic --partitions $partitions --replication-factor $replication_factor"
        fi
    else
        print_error "无法执行kafka-topics命令"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        print_success "成功创建Topic: $topic"
        return 0
    else
        print_error "创建Topic失败: $topic"
        return 1
    fi
}

# 列出所有Topics
list_topics() {
    local bootstrap_server=$1
    
    print_info "列出所有Topics:"
    
    if command -v kafka-topics &> /dev/null; then
        print_info "执行: kafka-topics --bootstrap-server $bootstrap_server --list"
        kafka-topics --bootstrap-server $bootstrap_server --list
    elif check_docker; then
        # 尝试找到运行中的Kafka容器
        local kafka_containers=$(docker ps -q -f name=kafka)
        local kafka_container=""
        
        # 获取第一个容器（如果有多个）
        for container in $kafka_containers; do
            kafka_container=$container
            break
        done
        
        if [ -n "$kafka_container" ]; then
            print_info "在容器 $kafka_container 中执行: kafka-topics --bootstrap-server $bootstrap_server --list"
            docker exec $kafka_container bash -c "kafka-topics --bootstrap-server $bootstrap_server --list"
        else
            print_info "使用临时容器执行: kafka-topics --bootstrap-server $bootstrap_server --list"
            docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-topics --bootstrap-server $bootstrap_server --list"
        fi
    else
        print_error "无法执行kafka-topics命令"
        return 1
    fi
    
    if [ $? -eq 0 ]; then
        return 0
    else
        print_error "列出Topics失败"
        return 1
    fi
}

# 发送测试消息
send_test_messages() {
    local bootstrap_server=$1
    local topic=$2
    local message=$3
    local num_messages=$4
    
    print_info "发送 $num_messages 条测试消息到Topic: $topic"
    
    for i in $(seq 1 $num_messages); do
        local msg="${message} (消息 $i)"
        
        # 直接使用Docker运行producer命令
        if command -v kafka-console-producer &> /dev/null; then
            echo "$msg" | kafka-console-producer \
                --bootstrap-server $bootstrap_server \
                --topic $topic
        elif check_docker; then
            # 尝试找到运行中的Kafka容器
            local kafka_containers=$(docker ps -q -f name=kafka)
            local kafka_container=""
            
            # 获取第一个容器（如果有多个）
            for container in $kafka_containers; do
                kafka_container=$container
                break
            done
            
            if [ -n "$kafka_container" ]; then
                echo "$msg" | docker exec $kafka_container bash -c "kafka-console-producer --bootstrap-server $bootstrap_server --topic $topic"
            else
                echo "$msg" | docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-producer --bootstrap-server $bootstrap_server --topic $topic"
            fi
        else
            print_error "无法执行kafka-console-producer命令"
            return 1
        fi
        
        if [ $? -eq 0 ]; then
            print_info "已发送消息: $msg"
        else
            print_error "发送消息失败: $msg"
            return 1
        fi
    done
    
    print_success "成功发送 $num_messages 条消息"
    return 0
}

# 消费测试消息
consume_test_messages() {
    local bootstrap_server=$1
    local topic=$2
    local num_messages=$3
    
    print_info "消费Topic $topic 中的最新 $num_messages 条消息:"
    
    # 使用超时机制避免无限等待
    if command -v timeout &> /dev/null; then
        # 由于timeout不能直接调用bash函数，我们需要特殊处理
        if command -v kafka-console-consumer &> /dev/null; then
            timeout 10s kafka-console-consumer \
                --bootstrap-server $bootstrap_server \
                --topic $topic \
                --from-beginning \
                --max-messages $num_messages \
                --timeout-ms 5000
        elif check_docker; then
            # 尝试找到运行中的Kafka容器
            local kafka_containers=$(docker ps -q -f name=kafka)
            local kafka_container=""
            
            # 获取第一个容器（如果有多个）
            for container in $kafka_containers; do
                kafka_container=$container
                break
            done
            
            if [ -n "$kafka_container" ]; then
                timeout 10s docker exec $kafka_container bash -c "kafka-console-consumer --bootstrap-server $bootstrap_server --topic $topic --from-beginning --max-messages $num_messages --timeout-ms 5000"
            else
                timeout 10s docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-consumer --bootstrap-server $bootstrap_server --topic $topic --from-beginning --max-messages $num_messages --timeout-ms 5000"
            fi
        else
            print_error "无法执行kafka-console-consumer命令"
            return 1
        fi
    else
        # 如果没有timeout命令，直接运行
        if command -v kafka-console-consumer &> /dev/null; then
            kafka-console-consumer \
                --bootstrap-server $bootstrap_server \
                --topic $topic \
                --from-beginning \
                --max-messages $num_messages \
                --timeout-ms 5000
        elif check_docker; then
            # 尝试找到运行中的Kafka容器
            local kafka_containers=$(docker ps -q -f name=kafka)
            local kafka_container=""
            
            # 获取第一个容器（如果有多个）
            for container in $kafka_containers; do
                kafka_container=$container
                break
            done
            
            if [ -n "$kafka_container" ]; then
                docker exec $kafka_container bash -c "kafka-console-consumer --bootstrap-server $bootstrap_server --topic $topic --from-beginning --max-messages $num_messages --timeout-ms 5000"
            else
                docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-console-consumer --bootstrap-server $bootstrap_server --topic $topic --from-beginning --max-messages $num_messages --timeout-ms 5000"
            fi
        else
            print_error "无法执行kafka-console-consumer命令"
            return 1
        fi
    fi
    
    local result=$?
    if [ $result -eq 0 ] || [ $result -eq 124 ]; then  # 124是timeout的退出码
        print_success "消息消费测试完成"
        return 0
    else
        print_error "消费消息失败"
        return 1
    fi
}

# 获取集群信息
get_cluster_info() {
    local bootstrap_server=$1
    
    print_info "获取集群信息:"
    
    if command -v kafka-cluster &> /dev/null; then
        print_info "执行: kafka-cluster --bootstrap-server $bootstrap_server --describe"
        kafka-cluster --bootstrap-server $bootstrap_server --describe
    elif check_docker; then
        # 尝试找到运行中的Kafka容器
        local kafka_containers=$(docker ps -q -f name=kafka)
        local kafka_container=""
        
        # 获取第一个容器（如果有多个）
        for container in $kafka_containers; do
            kafka_container=$container
            break
        done
        
        if [ -n "$kafka_container" ]; then
            print_info "在容器 $kafka_container 中执行: kafka-cluster --bootstrap-server $bootstrap_server --describe"
            docker exec $kafka_container bash -c "kafka-cluster --bootstrap-server $bootstrap_server --describe"
        else
            print_info "使用临时容器执行: kafka-cluster --bootstrap-server $bootstrap_server --describe"
            docker run --rm --network kafka-network confluentinc/cp-kafka:7.5.0 bash -c "kafka-cluster --bootstrap-server $bootstrap_server --describe"
        fi
    else
        print_warning "未找到kafka-cluster命令，跳过集群信息获取"
        return 0
    fi
    
    if [ $? -eq 0 ]; then
        return 0
    else
        print_warning "无法获取集群信息 (可能不支持此命令)"
        return 0  # 即使失败也返回0，因为这是一个可选步骤
    fi
}

# 主测试流程
run_tests() {
    local bootstrap_server=$1
    local topic=$2
    local message=$3
    local num_messages=$4
    
    print_info "开始Kafka访问验证测试"
    echo "----------------------------------------"
    
    # 1. 测试连接
    if ! test_connection $bootstrap_server; then
        print_error "连接测试失败，退出测试"
        return 1
    fi
    
    echo ""
    
    # 2. 获取集群信息
    get_cluster_info $bootstrap_server
    echo ""
    
    # 3. 创建测试Topic
    if ! create_test_topic $bootstrap_server $topic; then
        print_error "Topic创建失败，退出测试"
        return 1
    fi
    
    echo ""
    
    # 4. 列出所有Topics
    list_topics $bootstrap_server
    echo ""
    
    # 5. 发送测试消息
    if ! send_test_messages $bootstrap_server $topic "$message" $num_messages; then
        print_error "消息发送失败"
        return 1
    fi
    
    echo ""
    
    # 6. 消费测试消息
    if ! consume_test_messages $bootstrap_server $topic $num_messages; then
        print_error "消息消费失败"
        return 1
    fi
    
    echo ""
    print_success "所有测试完成!"
    return 0
}

# 主函数
main() {
    local bootstrap_server=$DEFAULT_BOOTSTRAP_SERVER
    local topic=$DEFAULT_TOPIC
    local message=$DEFAULT_MESSAGE
    local num_messages=$DEFAULT_NUM_MESSAGES
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -b|--bootstrap-server)
                bootstrap_server="$2"
                shift 2
                ;;
            -t|--topic)
                topic="$2"
                shift 2
                ;;
            -m|--message)
                message="$2"
                shift 2
                ;;
            -n|--num-messages)
                num_messages="$2"
                shift 2
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # 检查依赖
    if ! check_kafka_tools; then
        print_error "缺少必要的工具，请安装Kafka命令行工具或Docker"
        exit 1
    fi
    
    # 运行测试
    if run_tests $bootstrap_server $topic "$message" $num_messages; then
        exit 0
    else
        exit 1
    fi
}

# 执行主函数
main "$@"