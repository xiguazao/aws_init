# 使用轻量级 Python 镜像作为基础
FROM python:3.9-slim

# 安装 AWS CLI 和 Terraform
RUN apt-get update && \
    apt-get install -y curl unzip && \
    # 安装 AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    # 安装 Terraform
    curl -LO https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip && \
    unzip terraform_*.zip -d /usr/local/bin && \
    # 清理缓存，减少镜像体积
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* *.zip

# 设置工作目录和默认命令
WORKDIR /workspace
CMD ["/bin/bash"]

#docker run --rm -v $(pwd):/workspace -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY my-terraform-image terraform apply