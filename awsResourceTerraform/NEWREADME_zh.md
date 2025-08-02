# 使用Docker的AWS基础设施Terraform项目

本项目使用Terraform在Docker容器中配置完整的AWS基础设施。包括VPC、子网、安全组、NAT网关、EC2实例、RDS数据库、S3存储桶和CloudFront CDN。

## 架构概述

基础设施包括以下组件：

1. **VPC** - 虚拟私有云，包含公有和私有子网
2. **安全组** - 不同层级的网络访问控制
3. **NAT网关** - 私有子网实例的互联网访问
4. **EC2实例** - Web和应用服务器
5. **RDS** - 托管数据库服务
6. **S3** - 对象存储
7. **CloudFront** - 内容分发网络

## 前提条件

1. 系统上已安装Docker
2. AWS凭证（访问密钥ID和秘密访问密钥）
3. AWS账户中已存在的EC2密钥对

## 目录结构

```
aws-terraform/
├── Dockerfile              # Docker镜像定义
├── docker-compose.yml      # Docker Compose配置
├── terraform-runner.sh     # 运行Terraform命令的辅助脚本
├── main.tf                 # 主Terraform配置
├── variables.tf            # 输入变量
├── outputs.tf              # 输出值
├── backend.tf              # 后端配置模板
├── modules/                # 可重用模块
│   ├── vpc/                # VPC模块
│   ├── security-groups/    # 安全组模块
│   ├── nat-gateway/        # NAT网关模块
│   ├── ec2/                # EC2实例模块
│   ├── rds/                # RDS数据库模块
│   ├── s3/                 # S3存储桶模块
│   └── cdn/                # CloudFront CDN模块
└── NEWREADME_zh.md         # 本文档
```

## Docker镜像

Docker镜像基于Python基础镜像构建，包含：

- AWS CLI
- Terraform

### 构建Docker镜像

使用terraform-runner.sh脚本运行任何命令时会自动构建Docker镜像。或者，您可以手动构建：

```bash
docker-compose build
```

## 配置

在部署基础设施之前，您需要配置AWS凭证和其他变量。

### AWS凭证

您需要将AWS凭证设置为环境变量：

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
# 可选，仅在使用临时凭证时需要
# export AWS_SESSION_TOKEN="your-session-token"
```

### Terraform变量

可以通过[variables.tf](variables.tf)中的变量自定义基础设施：

| 变量 | 描述 | 默认值 |
|------|------|--------|
| `aws_region` | AWS区域 | us-east-1 |
| `project_name` | 资源命名的项目名称 | HMBS |
| `vpc_cidr` | VPC的CIDR块 | 10.0.0.0/16 |
| `availability_zones` | 可用区 | ["us-east-1a", "us-east-1b"] |
| `public_subnets` | 公有子网CIDR块 | ["10.0.1.0/24", "10.0.2.0/24"] |
| `private_subnets` | 私有子网CIDR块 | ["10.0.3.0/24", "10.0.4.0/24"] |
| `key_pair_name` | EC2密钥对名称 | my-key-pair |
| `ec2_instance_type` | EC2实例类型 | t3.micro |
| `ec2_ami_id` | EC2 AMI ID | Amazon Linux 2 |
| `db_instance_class` | 数据库实例类别 | db.t3.micro |
| `db_name` | 数据库名称 | myappdb |
| `db_username` | 数据库用户名 | admin |
| `db_password` | 数据库密码 | MySecurePassword123! |

## 使用terraform-runner.sh

使用本项目的最简单方法是使用[terraform-runner.sh](terraform-runner.sh)脚本：

### 初始化Terraform

```bash
./terraform-runner.sh init
```

### 规划变更

```bash
./terraform-runner.sh plan
```

### 应用变更

```bash
./terraform-runner.sh apply
```

### 销毁基础设施

```bash
./terraform-runner.sh destroy
```

### 格式化配置文件

```bash
./terraform-runner.sh fmt
```

### 验证配置

```bash
./terraform-runner.sh validate
```

### 获取Shell访问权限

```bash
./terraform-runner.sh shell
```

## 使用Docker Compose手动操作

您也可以使用Docker Compose手动运行Terraform命令：

### 初始化Terraform

```bash
docker-compose run --rm terraform terraform init
```

### 规划变更

```bash
docker-compose run --rm terraform terraform plan
```

### 应用变更

```bash
docker-compose run --rm terraform terraform apply
```

### 销毁基础设施

```bash
docker-compose run --rm terraform terraform destroy
```

## 后端配置

本项目在[backend.tf](backend.tf)中包含远程状态存储的模板。默认情况下，Terraform将状态存储在本地，但对于生产环境，建议使用远程状态存储。

要使用远程状态（例如S3）：

1. 取消注释并自定义[backend.tf](backend.tf)中的S3后端部分
2. 创建所需的S3存储桶和DynamoDB表（如果使用状态锁定）
3. 运行`./terraform-runner.sh init -reconfigure`应用后端配置

远程状态提供以下功能：
- 团队成员之间的状态共享
- 状态锁定以防止并发修改
- 状态备份和版本控制

## 模块

### VPC模块

创建跨多个可用区的VPC，包含公有和私有子网。

**资源：**
- VPC
- 互联网网关
- 公有和私有子网
- 公有路由表
- 路由表关联

### 安全组模块

为应用程序的不同层级创建安全组：

**资源：**
- Web安全组（HTTP、HTTPS、SSH访问）
- 应用安全组（内部通信）
- 数据库安全组（MySQL访问）

### NAT网关模块

为私有子网的互联网访问创建NAT网关：

**资源：**
- 弹性IP
- NAT网关
- 私有路由表
- 路由表关联

### EC2模块

创建Web和应用服务器的EC2实例：

**资源：**
- Web服务器（在公有子网中）
- 应用服务器（在私有子网中）

### RDS模块

创建托管MySQL数据库：

**资源：**
- DB子网组
- RDS实例

### S3模块

创建用于对象存储的S3存储桶：

**资源：**
- S3存储桶
- 存储桶ACL
- 存储桶版本控制

### CDN模块

创建用于内容分发的CloudFront分发：

**资源：**
- CloudFront分发
- 源访问身份

## 输出

应用配置后，Terraform将输出以下信息：

- VPC ID和CIDR块
- 公有和私有子网ID
- 安全组ID
- NAT网关ID
- EC2实例ID和公网IP
- RDS端点和实例ID
- S3存储桶ID和域名
- CloudFront域名和分发ID

## 架构图

```
Internet
    │
    ▼
Internet Gateway
    │
    ▼
Public Subnets ───┐
    │             │
    ▼             ▼
Web Servers    NAT Gateways
    │             │
    ▼             ▼
Application  Private Subnets
  Servers          │
    │             ▼
    ▼         RDS Database
Internal
Communication
```

## 安全性

- Web服务器放置在具有受限入站访问的公有子网中
- 应用服务器放置在没有直接互联网访问的私有子网中
- 数据库服务器在私有子网中，仅可从应用服务器访问
- 层次之间的所有流量都由安全组控制

## 高可用性

- 资源分布在多个可用区中
- NAT网关部署在每个可用区中
- 每个层级在多个可用区中都有实例

## 成本优化

- 默认使用具有成本效益的实例类型
- 利用AWS托管服务（RDS、S3、CloudFront）降低运营开销