# Elasticsearch 集群部署

这个目录包含了使用Docker Compose部署Elasticsearch集群的配置文件。

## 架构

提供了三种部署方式：
1. 单节点部署：适用于开发和测试环境
2. 高可用部署：在单台机器上运行多个节点组成的集群
3. 跨节点高可用集群部署：在多台物理机上部署高可用集群

## 目录结构

```
elasticsearch/
├── single-node/         # 单节点部署配置
│   └── docker-compose.yml
├── high-availability/   # 高可用部署配置
│   ├── master/          # Master节点配置（包含Kibana）
│   │   └── docker-compose.yml
│   ├── node1/           # 数据节点1配置
│   │   └── docker-compose.yml
│   └── node2/           # 数据节点2配置
│   │   └── docker-compose.yml
├── multi-node/          # 跨节点高可用集群部署配置
│   ├── master/          # Master节点配置（包含Kibana）
│   │   └── docker-compose.yml
│   ├── node1/           # 数据节点1配置
│   │   └── docker-compose.yml
│   └── node2/           # 数据节点2配置
│       └── docker-compose.yml
├── kibana/              # Kibana独立配置
│   ├── docker-compose.yml
│   └── README.md
├── README.md            # 说明文档
└── simple-test.sh       # 简单验证脚本
```

## 部署前准备

### 系统要求
1. 每个节点都需要安装Docker和Docker Compose
2. 确保节点间网络互通
3. 开放必要的端口：
   - Elasticsearch: 9200, 9300
   - Kibana: 5601 (可选)

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

## 部署步骤

### 单节点部署
1. 进入[single-node](file:///home/melon/aws_init/services/elasticsearch/single-node)目录
2. 运行以下命令启动Elasticsearch和Kibana：
   ```bash
   docker-compose up -d
   ```
3. 等待服务启动完成（约1-2分钟）
4. 验证服务状态：
   ```bash
   docker-compose ps
   ```

### 高可用部署
1. 进入[high-availability](file:///home/melon/aws_init/services/elasticsearch/high-availability)目录
2. 分别进入[master](file:///home/melon/aws_init/services/elasticsearch/high-availability/master)、[node1](file:///home/melon/aws_init/services/elasticsearch/high-availability/node1)和[node2](file:///home/melon/aws_init/services/elasticsearch/high-availability/node2)目录
3. 按顺序启动各节点（建议先启动master节点）：
   ```bash
   # 在master目录（包含Elasticsearch Master节点和Kibana）
   docker-compose up -d
   
   # 等待master节点启动后，在node1和node2目录分别执行
   docker-compose up -d
   ```
4. 等待所有节点启动并形成集群（约2-3分钟）
5. 验证集群状态：
   ```bash
   curl http://localhost:9200/_cluster/health?pretty
   ```

### 跨节点高可用集群部署
1. 在每台物理机上创建相应的目录结构
2. 将对应目录下的配置文件复制到相应节点
3. 根据实际网络环境修改配置文件中的IP地址
4. 在每个节点上运行以下命令启动服务（建议先启动master节点）：
   ```bash
   docker-compose up -d
   ```
5. 等待所有节点启动并形成集群（约2-3分钟）
6. 验证集群状态：
   ```bash
   curl http://<any-node-ip>:9200/_cluster/health?pretty
   ```

## 访问服务

### 单节点
- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

### 高可用部署
- Elasticsearch: http://localhost:9200
- Kibana: http://localhost:5601

### 跨节点高可用集群部署
- Elasticsearch: http://<any-node-ip>:9200
- Kibana: http://<master-node-ip>:5601

## 简单访问验证

项目提供了一个简单的验证脚本：

```bash
# 验证本地Elasticsearch
./simple-test.sh

# 验证远程Elasticsearch
./simple-test.sh 10.0.1.10:9200
```

## 管理Elasticsearch集群

### 常用管理命令

进入Elasticsearch容器执行管理命令：
```bash
docker exec -it elasticsearch bash
```

检查集群健康状态：
```bash
curl -X GET "localhost:9200/_cluster/health?pretty"
```

查看集群节点信息：
```bash
curl -X GET "localhost:9200/_nodes?pretty"
```

查看所有索引：
```bash
curl -X GET "localhost:9200/_cat/indices?v"
```

创建索引：
```bash
curl -X PUT "localhost:9200/test-index?pretty"
```

添加文档：
```bash
curl -X POST "localhost:9200/test-index/_doc/?pretty" -H 'Content-Type: application/json' -d'
{
  "title": "Test Document",
  "content": "This is a test document"
}
'
```

搜索文档：
```bash
curl -X GET "localhost:9200/test-index/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "title": "Test"
    }
  }
}
'
```

## Kibana 配置与集成

Kibana已集成到以下部署配置中：
1. 单节点部署 - Kibana与Elasticsearch在同一配置文件中
2. 高可用部署 - Kibana集成在Master节点配置中
3. 跨节点部署 - Kibana集成在Master节点配置中

### 独立部署Kibana
如果需要独立部署Kibana，可以使用[kibana](file:///home/melon/aws_init/services/elasticsearch/kibana)目录中的配置：

1. 进入[kibana](file:///home/melon/aws_init/services/elasticsearch/kibana)目录
2. 修改`ELASTICSEARCH_HOSTS`环境变量以指向正确的Elasticsearch节点
3. 启动Kibana：
   ```bash
   docker-compose up -d
   ```

### Kibana配置说明

Kibana的关键配置包括：
- `ELASTICSEARCH_HOSTS`: Elasticsearch集群地址列表
- `SERVER_NAME`: Kibana服务器名称

### 访问Kibana

Kibana默认通过5601端口提供Web界面访问：
- 单节点和高可用部署: http://localhost:5601
- 跨节点部署: http://<master-node-ip>:5601

## 停止和清理

### 单节点
停止服务：
```bash
docker-compose down
```

停止并删除所有数据卷：
```bash
docker-compose down -v
```

### 高可用部署
在每个节点目录中执行：
```bash
docker-compose down
```

或者删除所有数据卷：
```bash
docker-compose down -v
```

### 跨节点高可用集群部署
在每个物理节点上执行：
```bash
docker-compose down
```

或者删除所有数据卷：
```bash
docker-compose down -v
```

## 故障排除

### 查看日志
```bash
# 查看Elasticsearch日志
docker-compose logs elasticsearch

# 查看Kibana日志
docker-compose logs kibana

# 实时查看日志
docker-compose logs -f elasticsearch
```

### 常见问题
1. 如果遇到"max virtual memory areas vm.max_map_count [65530] is too low"错误，请增加系统限制
2. 如果节点无法加入集群，请检查网络连接和配置文件中的IP地址
3. 如果端口冲突，请修改docker-compose.yml中的端口映射
4. 确保所有节点使用相同的`cluster.name`
5. 如果启动时报错"container has already joined cluster"，请清理数据卷后重新启动
6. 如果遇到内存不足问题，请调整`ES_JAVA_OPTS`中的内存设置
7. 如果Kibana无法连接到Elasticsearch，请检查：
   - Elasticsearch服务是否正在运行
   - 网络连接是否正常
   - `ELASTICSEARCH_HOSTS`配置是否正确

## 性能优化建议

1. 根据实际硬件配置调整JVM堆内存大小：
   ```yaml
   environment:
     - "ES_JAVA_OPTS=-Xms2g -Xmx2g"
   ```

2. 为生产环境启用安全功能：
   ```yaml
   environment:
     - xpack.security.enabled=true
   ```

3. 配置适当的分片和副本数：
   ```bash
   curl -X PUT "localhost:9200/my-index" -H 'Content-Type: application/json' -d'
   {
     "settings": {
       "number_of_shards": 3,
       "number_of_replicas": 2
     }
   }'
   ```

4. 根据数据访问模式配置合适的节点角色（master、data、ingest等）