#!/bin/bash

# Elasticsearch 简单验证脚本

ELASTICSEARCH_URL=${1:-http://localhost:9200}
CLUSTER_HEALTH_URL="$ELASTICSEARCH_URL/_cluster/health"
NODES_URL="$ELASTICSEARCH_URL/_nodes"
INDICES_URL="$ELASTICSEARCH_URL/_cat/indices?v"

echo "测试Elasticsearch连接: $ELASTICSEARCH_URL"

# 测试连接
echo "=== 检查集群健康状态 ==="
if curl -s -f "$CLUSTER_HEALTH_URL" > /dev/null; then
    echo "✓ 成功连接到Elasticsearch集群"
    curl -s "$CLUSTER_HEALTH_URL?pretty"
else
    echo "✗ 无法连接到Elasticsearch集群"
    exit 1
fi

echo ""
echo "=== 集群节点信息 ==="
curl -s "$NODES_URL?pretty" | jq '.nodes | keys[] as $k | .[$k] | {name: .name, roles: .roles, version: .version}'

echo ""
echo "=== 集群统计信息 ==="
curl -s "$ELASTICSEARCH_URL/_cluster/stats?pretty" | jq '{number_of_nodes: .number_of_nodes, number_of_data_nodes: .number_of_data_nodes, active_shards: .indices.shards.total}'

echo ""
echo "=== 索引列表 ==="
curl -s "$INDICES_URL"

echo ""
echo "=== 创建测试索引 ==="
curl -X PUT "$ELASTICSEARCH_URL/test-index?pretty" -H 'Content-Type: application/json'

echo ""
echo "=== 添加测试文档 ==="
curl -X POST "$ELASTICSEARCH_URL/test-index/_doc/1?pretty" -H 'Content-Type: application/json' -d'
{
  "title": "Elasticsearch Test Document",
  "content": "This is a test document for Elasticsearch validation",
  "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
}'

echo ""
echo "=== 搜索测试文档 ==="
sleep 1  # 等待文档被索引
curl -X GET "$ELASTICSEARCH_URL/test-index/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "title": "Test"
    }
  }
}'

echo ""
echo "=== 删除测试索引 ==="
curl -X DELETE "$ELASTICSEARCH_URL/test-index?pretty"

echo ""
echo "=== 测试完成 ==="