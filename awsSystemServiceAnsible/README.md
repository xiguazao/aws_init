# System Initialization with Ansible Roles

This directory contains Ansible roles and playbooks to initialize Rocky Linux 9 systems according to the specifications in the system.md document.

## Overview

The Ansible implementation has been restructured to use roles for better organization and reusability:
1. System initialization for Rocky Linux 9
2. Docker installation and configuration
3. Nginx deployment (for proxy servers)
4. Redis deployment (for Redis servers)

## Project Structure

```
.
├── README.md
├── site.yml                    # Main playbook
├── server-config.ini           # Server configuration file
├── group_vars/
│   └── all.yml                 # Global variables for all hosts
├── roles/
│   ├── system/                 # System initialization role
│   │   ├── tasks/
│   │   │   └── main.yml        # System tasks
│   │   ├── templates/
│   │   │   └── sysctl.conf.j2  # Kernel parameters template
│   │   └── vars/
│   │       └── main.yml        # System variables
│   ├── docker/                 # Docker installation role
│   │   ├── tasks/
│   │   │   └── main.yml        # Docker tasks
│   │   └── vars/
│   │       └── main.yml        # Docker variables
│   ├── nginx/                  # Nginx deployment role
│   │   ├── tasks/
│   │   │   └── main.yml        # Nginx tasks
│   │   ├── templates/
│   │   │   └── docker-compose.yml.j2  # Nginx docker-compose template
│   │   └── vars/
│   │       └── main.yml        # Nginx variables
│   └── redis/                  # Redis deployment role
│       ├── tasks/
│       │   └── main.yml        # Redis tasks
│       ├── templates/
│       │   └── docker-compose.yml.j2  # Redis docker-compose template
│       └── vars/
│           └── main.yml        # Redis variables
└── system.md
```

## Prerequisites

1. Ansible installed on the control machine
2. Target servers running Rocky Linux 9
3. SSH access to target servers

## Usage

1. Update your Ansible inventory file to include your servers:
   ```ini
   [all]
   server1 ansible_host=192.168.1.10
   server2 ansible_host=192.168.1.11
   
   [proxy_servers]
   server1
   
   [redis_servers]
   server2
   ```

2. Run the playbook:
   ```bash
   ansible-playbook -i inventory site.yml
   ```

## Server Configuration

The `server-config.ini` file contains all the server configuration parameters in INI format. This file can be used to:
- Document the system configuration
- Provide a reference for manual configuration
- Serve as a base for configuration management tools

The INI file is organized in sections:
- `[system]` - System information and versions
- `[users]` - Users to be created
- `[groups]` - Groups to be created
- `[directories]` - Directories to be created
- `[security]` - Security settings
- `[packages]` - Packages to be installed
- `[network]` - Network settings
- `[services]` - Service settings
- `[sysctl]` - Kernel parameters
- `[users_to_remove]` - Unnecessary users to be removed

## Roles Description

### System Role
Handles the base system initialization including:
- System compatibility check for Rocky Linux 9
- Package management (install/update/remove)
- User and group management
- Directory creation with proper permissions
- Security configurations (file permissions, aliases, polkit)
- System tuning (sysctl parameters, timeouts, history limits)

### Docker Role
Installs and configures Docker:
- Docker repository setup
- Docker engine installation
- Docker service configuration
- Docker Compose installation

### Nginx Role
Deploys Nginx service using docker-compose:
- Creates Nginx configuration directory
- Generates docker-compose file from template
- Starts Nginx container

### Redis Role
Deploys Redis service using docker-compose:
- Creates Redis data directory
- Generates docker-compose file from template
- Starts Redis container

## Customization

You can customize each role by modifying the variables in their respective `vars/main.yml` files:
- `roles/system/vars/main.yml` - System variables
- `roles/docker/vars/main.yml` - Docker variables
- `roles/nginx/vars/main.yml` - Nginx variables
- `roles/redis/vars/main.yml` - Redis variables

You can also modify global variables in:
- `group_vars/all.yml` - Global variables for all hosts

## Features Implemented

### System Initialization
- System compatibility check for Rocky Linux 9
- Package management (install/update/remove)
- User and group management
- Directory creation with proper permissions
- Security configurations (file permissions, aliases, polkit)
- System tuning (sysctl parameters, timeouts, history limits)

### Docker Installation
- Docker repository setup
- Docker engine installation
- Docker service configuration
- Docker Compose installation

### Service Deployment
- Nginx deployment with docker-compose
- Redis deployment with docker-compose

## Directory Structure

After running the playbook, the following directories will be created:
- `/opt/nginx` - Nginx configuration and docker-compose file
- `/opt/redis` - Redis configuration and docker-compose file
- Various system directories as specified in the original script

## Notes

- The playbook follows the same security practices as the original script
- SELinux is kept in enforcing mode
- iptables is configured as the firewall (firewalld is disabled)
- System services are properly configured and started