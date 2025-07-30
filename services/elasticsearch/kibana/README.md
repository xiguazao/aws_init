# Kibana 独立部署配置

这个目录包含了用于独立部署Kibana的配置文件，可以与任何Elasticsearch部署配合使用。

## 目录结构

```
kibana/
├── docker-compose.yml  # Kibana独立部署配置
└── README.md           # 说明文档
```

## 部署方式

### 与单节点Elasticsearch一起部署
单节点Elasticsearch配置中已包含Kibana服务，直接使用即可。

### 与高可用Elasticsearch一起部署
高可用Elasticsearch的Master节点配置中已包含Kibana服务，直接使用即可。

### 与跨节点Elasticsearch一起部署
跨节点Elasticsearch的Master节点配置中已包含Kibana服务，直接使用即可。

### 独立部署Kibana
如果需要独立部署Kibana，可以使用此目录中的配置：

1. 修改`ELASTICSEARCH_HOSTS`环境变量以指向正确的Elasticsearch节点
2. 运行以下命令启动Kibana：
   ```bash
   docker-compose up -d
   ```

## 配置说明

### 环境变量

- `ELASTICSEARCH_HOSTS`: Elasticsearch集群地址列表
- `SERVER_NAME`: Kibana服务器名称

### 网络配置

Kibana需要能够访问Elasticsearch节点。根据部署方式不同，可能需要调整网络配置：

1. **与Elasticsearch在同一Docker网络中**：
   - 确保Kibana与Elasticsearch容器在同一个网络中
   - 使用服务名称或容器名称作为主机名

2. **访问远程Elasticsearch集群**：
   - 使用Elasticsearch节点的实际IP地址和端口
   - 确保网络防火墙允许相应端口的通信

## 访问Kibana

Kibana默认通过5601端口提供Web界面访问：

- URL: http://<kibana-host>:5601
- 默认情况下没有用户名和密码（因为Elasticsearch禁用了安全功能）

## 停止和清理

停止Kibana服务：
```bash
docker-compose down
```

## 故障排除

### 查看日志
```bash
# 查看Kibana日志
docker-compose logs kibana

# 实时查看日志
docker-compose logs -f kibana
```

### 常见问题

1. 如果Kibana无法连接到Elasticsearch，请检查：
   - Elasticsearch服务是否正在运行
   - 网络连接是否正常
   - `ELASTICSEARCH_HOSTS`配置是否正确
   - 防火墙是否阻止了连接

2. 如果Kibana界面无法访问，请检查：
   - Kibana服务是否正在运行
   - 端口映射是否正确
   - 防火墙是否阻止了5601端口

3. 如果出现内存不足错误，请检查：
   - Docker容器的资源限制
   - 主机的可用内存