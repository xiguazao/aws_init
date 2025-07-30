# Terraform Docker Image for AWS Infrastructure Management
FROM hashicorp/terraform:latest

# Set working directory
WORKDIR /terraform

# Install additional tools
RUN apk add --no-cache \
    bash \
    curl \
    jq \
    python3 \
    py3-pip \
    aws-cli

# Install AWS CLI v2 (more recent than v1 available in apk)
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    sudo ./aws/install && \
    rm -rf awscliv2.zip aws/

# Create non-root user
RUN addgroup -g 1001 -S terraform && \
    adduser -u 1001 -S terraform -G terraform

# Set ownership of working directory
RUN chown -R terraform:terraform /terraform

# Switch to non-root user
USER 1001

# Copy Terraform files
COPY --chown=terraform:terraform . .

# Create directory for AWS credentials
RUN mkdir -p /home/terraform/.aws

# Set entrypoint
ENTRYPOINT ["/bin/bash"]