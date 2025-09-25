# DDD Hexagonal Workshop - Deployment Scripts

Welcome! This guide will help you deploy the **Domain-Driven Design (DDD) with Hexagonal Architecture Workshop** using our unified deployment system.

> ✅ **Status**: The consolidated deployment script has been fully tested and is production-ready!

## 🚀 Quick Start

### For Workshop Instructors (Multi-User)
```bash
# 0. cd into the scripts directory
cd scripts

# 1. Setup cluster prerequisites (one-time)
./deploy-workshop.sh --cluster-setup

# 2. Deploy workshop for 20 users with custom password
./deploy-workshop.sh --workshop --count 20 --password "Workshop2024"

# 3. Generate access URLs for participants
./deploy-workshop.sh --workshop --generate-urls --count 20
```

### For Individual Developers (Single-User)
```bash
# Deploy personal workshop environment
./deploy-workshop.sh --single-user --namespace my-ddd-workshop
```

## 📋 Prerequisites

### Required Access
- **OpenShift cluster** (version 4.14+)
- **Cluster admin permissions** (for multi-user workshops)
- **Namespace admin or self-provisioner** (for single-user deployments)

### Required Tools
- `oc` (OpenShift CLI) - logged into your cluster
- `bash` shell environment

### Verify Prerequisites
```bash
# Check OpenShift login
oc whoami

# Check cluster version
oc version

# Verify admin permissions (for multi-user)
oc auth can-i create clusterroles
```

## 🎯 Deployment Modes

### 1. Multi-User Workshop Mode (`--workshop`)

**Use Case**: Training sessions, workshops, classrooms

**Basic Usage**:
```bash
# Create 15 numbered users (user1, user2, ..., user15)
./deploy-workshop.sh --workshop --count 15

# Use specific usernames
./deploy-workshop.sh --workshop --users "alice,bob,charlie,diana"

# Load users from file
./deploy-workshop.sh --workshop --users-file participants.txt

# Use existing HTPasswd users
./deploy-workshop.sh --workshop --use-existing
```

**Advanced Options**:
```bash
# Custom password for created users
./deploy-workshop.sh --workshop --count 20 --password "MySecurePass123"

# Custom user prefix
./deploy-workshop.sh --workshop --count 10 --user-prefix "student"

# Incremental deployment (add to existing)
./deploy-workshop.sh --workshop --count 25 --incremental
```

### 2. Single-User Mode (`--single-user`)

**Use Case**: Individual developers, personal learning

```bash
# Deploy to default namespace
./deploy-workshop.sh --single-user

# Deploy to custom namespace
./deploy-workshop.sh --single-user --namespace my-workshop

# Cleanup when done
./deploy-workshop.sh --single-user --cleanup --namespace my-workshop
```

### 3. Cluster Setup Mode (`--cluster-setup`)

**Use Case**: One-time cluster preparation

```bash
# Install OpenShift Dev Spaces operator and configure cluster
./deploy-workshop.sh --cluster-setup
```

### 4. Test Mode (`--test`)

**Use Case**: Validation and troubleshooting

```bash
# Test multi-user workshop
./deploy-workshop.sh --test --workshop --count 10

# Test single-user deployment
./deploy-workshop.sh --test --single-user

# Test specific users
./deploy-workshop.sh --test --workshop --users "user1,user2,user3"
```

## 📝 Common Workflows

### New Workshop Setup (Complete)
```bash
# 1. Setup cluster (one-time)
./deploy-workshop.sh --cluster-setup

# 2. Deploy for participants
./deploy-workshop.sh --workshop --count 25 --password "Workshop2024"

# 3. Test deployment
./deploy-workshop.sh --test --workshop --count 25

# 4. Generate access URLs
./deploy-workshop.sh --workshop --generate-urls --count 25
```

### Adding More Users to Existing Workshop
```bash
# Scale from 20 to 30 users
./deploy-workshop.sh --workshop --count 30 --incremental --password "Workshop2024"
```

### Personal Development Environment
```bash
# Setup personal environment
./deploy-workshop.sh --single-user --namespace ddd-learning

# Test it works
./deploy-workshop.sh --test --single-user

# Access your environment
echo "Visit: https://devspaces.apps.<your-cluster-domain>/#https://github.com/tosin2013/dddhexagonalworkshop.git&devfilePath=devfile.yaml"
```

## 🔧 Configuration Options

### User Management
| Option | Description | Example |
|--------|-------------|---------|
| `--count NUMBER` | Create numbered users | `--count 20` |
| `--users LIST` | Comma-separated usernames | `--users "alice,bob"` |
| `--users-file FILE` | Load users from file | `--users-file users.txt` |
| `--use-existing` | Use existing HTPasswd users | `--use-existing` |
| `--password PASS` | Password for created users | `--password "SecurePass123"` |
| `--user-prefix PREFIX` | User prefix (default: user) | `--user-prefix "student"` |

### Deployment Control
| Option | Description | Example |
|--------|-------------|---------|
| `--namespace NAME` | Target namespace | `--namespace my-workshop` |
| `--incremental` | Add to existing deployment | `--incremental` |
| `--cleanup` | Remove deployed resources | `--cleanup` |
| `--generate-urls` | Generate access URLs only | `--generate-urls` |

### Utility Options
| Option | Description | Example |
|--------|-------------|---------|
| `--dry-run` | Show what would be done | `--dry-run` |
| `--force` | Skip confirmation prompts | `--force` |
| `--verbose` | Enable verbose output | `--verbose` |
| `--help` | Show help message | `--help` |

## 📊 Resource Planning

### Per-User Resource Requirements
- **CPU**: 350m (request) / 1000m (limit)
- **Memory**: 960Mi (request) / 1920Mi (limit)
- **Storage**: Dynamic provisioning required

### Cluster Capacity Guidelines
| Users | Total CPU | Total Memory | Recommended Nodes |
|-------|-----------|--------------|-------------------|
| 10    | 3.5 cores | 9.6Gi       | 2 worker nodes    |
| 20    | 7 cores   | 19.2Gi      | 3 worker nodes    |
| 35    | 12.25 cores | 33.6Gi    | 5 worker nodes    |

## 🔍 Troubleshooting

### Common Issues

**"Not logged into OpenShift"**
```bash
oc login https://api.<your-cluster-domain>:6443
```

**"Insufficient permissions"**
- Ensure you have cluster-admin role for multi-user deployments
- Contact your cluster administrator

**"Dev Spaces operator not found"**
```bash
./deploy-workshop.sh --cluster-setup
```

**"DevWorkspace failed to start"**
```bash
# Check workspace status
oc get devworkspace -A

# View logs
oc describe devworkspace <workspace-name> -n <namespace>
```

### Diagnostic Commands
```bash
# Check cluster resources
oc get nodes
oc describe nodes

# Check Dev Spaces installation
oc get pods -n openshift-devspaces

# Run comprehensive tests
./deploy-workshop.sh --test --workshop --use-existing
```

## 📚 What Gets Created

### For Each Workshop User
- ✅ **Dedicated namespace**: `{username}-devspaces`
- ✅ **Resource quotas**: CPU, memory, and storage limits
- ✅ **RBAC permissions**: Namespace admin access
- ✅ **DevWorkspace**: Complete development environment
- ✅ **Services**: PostgreSQL database, Kafka messaging
- ✅ **Development tools**: Java 21, Maven, Git, VS Code

### Access Information
Users receive:
- **Dev Spaces URL**: Direct link to their development environment
- **Login credentials**: Username and password
- **Namespace**: Their dedicated workspace
- **Getting started guide**: Workshop instructions

## 🆘 Getting Help

### Built-in Help
```bash
./deploy-workshop.sh --help
```

### Documentation
- **[Consolidated Scripts Guide](../docs/CONSOLIDATED_SCRIPTS_GUIDE.md)**: Complete reference
- **[Deployment Guide](../docs/DEPLOYMENT_GUIDE.md)**: Detailed deployment instructions
- **[Troubleshooting Guide](../docs/TROUBLESHOOTING.md)**: Common issues and solutions

### Support
- **Repository**: https://github.com/tosin2013/dddhexagonalworkshop
- **Issues**: Report problems via GitHub issues
- **Discussions**: Community support and questions

## 🔧 Recent Updates

### ✅ **Script Consolidation Complete** (Latest)
- **Fixed all hanging issues**: Resolved library loading and function call problems
- **Comprehensive testing**: All modes (`--workshop`, `--single-user`, `--cluster-setup`, `--test`) verified
- **Production ready**: Successfully tested with multi-user deployments
- **Improved error handling**: Better validation and user feedback
- **ShellCheck validated**: Code quality verified with static analysis

### 🧪 **Verified Functionality**
```bash
# All these commands have been tested and work correctly:
./deploy-workshop.sh --help                    # ✅ Shows comprehensive help
./deploy-workshop.sh --cluster-setup           # ✅ Sets up Dev Spaces
./deploy-workshop.sh --workshop --count 5 --password "test123" --dry-run  # ✅ Dry run works
./deploy-workshop.sh --workshop --count 33 --password "yvm7guinouow7FPG"  # ✅ Real deployment works
```

---

**Ready to deploy?** Start with `./deploy-workshop.sh --help` to see all available options!
