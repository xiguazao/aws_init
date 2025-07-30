# Elasticsearch Cluster with Docker Compose

This directory contains configuration for deploying an Elasticsearch cluster using separate Docker Compose files for each node:
- 1 Master node (in the [master](master/) directory)
- 2 Data nodes (in the [node1](node1/) and [node2](node2/) directories)
- All using host network mode

## Cluster Configuration

The cluster is defined with separate docker-compose.yaml files for each node:
- Master node runs on IP 10.170.0.2, port 9200
- Data node 1 runs on IP 10.170.0.3, port 9201
- Data node 2 runs on IP 10.170.0.4, port 9202

Each node uses host network mode for better performance and simpler networking.

## Configuration Management

Environment variables have been moved to separate `.env` files for better configuration management:
- [master/elasticsearch.env](master/elasticsearch.env)
- [node1/elasticsearch.env](node1/elasticsearch.env)
- [node2/elasticsearch.env](node2/elasticsearch.env)

Passwords are managed through Docker secrets:
- [master/password.txt](master/password.txt)
- [node1/password.txt](node1/password.txt)
- [node2/password.txt](node2/password.txt)

Security features are enabled with:
- `xpack.security.enabled=true`
- `xpack.security.transport.ssl.enabled=true`

## Prerequisites

1. Docker installed on each server
2. Docker Compose installed on each server
3. Sufficient memory (at least 2GB available per node)
4. Network interfaces configured with the following IP addresses:
   - 10.170.0.2 (for master node server)
   - 10.170.0.3 (for node1 server)
   - 10.170.0.4 (for node2 server)

## Setup and Deployment

1. On each server, increase vm.max_map_count:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   ```

2. Update password files with secure passwords:
   ```bash
   # Edit each password.txt file with a secure password
   echo "your_secure_password" > master/password.txt
   echo "your_secure_password" > node1/password.txt
   echo "your_secure_password" > node2/password.txt
   ```

3. Deploy each node on its respective server:
   ```bash
   # On master server (10.170.0.2)
   cd master
   docker-compose up -d
   
   # On node1 server (10.170.0.3)
   cd node1
   docker-compose up -d
   
   # On node2 server (10.170.0.4)
   cd node2
   docker-compose up -d
   ```

4. Check the status of the containers on each server:
   ```bash
   docker-compose ps
   ```

## Accessing the Cluster

Once running, you can access:
- Master node: http://10.170.0.2:9200
- Node 1: http://10.170.0.3:9201
- Node 2: http://10.170.0.4:9202

Check cluster health:
```bash
curl http://10.170.0.2:9200/_cluster/health?pretty
```

With security enabled, you'll need to authenticate with the elastic user:
```bash
curl -u elastic:http://10.170.0.2:9200/_cluster/health?pretty
```

## Customizing Configuration

To modify the Elasticsearch configuration:
1. Edit the appropriate `elasticsearch.env` file in each node's directory
2. Update passwords in the `password.txt` files as needed
3. Restart the corresponding node with:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

## Stopping the Cluster

To stop each node, run on each respective server:
```bash
docker-compose down
```

To stop and remove data volumes:
```bash
docker-compose down -v
```