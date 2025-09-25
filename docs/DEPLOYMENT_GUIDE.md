# OpenShift Deployment Guide
## DDD Hexagonal Architecture Workshop

This guide provides comprehensive instructions for deploying the DDD Hexagonal Architecture Workshop to OpenShift clusters using the new consolidated script system.

> **🆕 New Consolidated Scripts**: This workshop now uses a unified deployment system. See the **[Consolidated Scripts Guide](CONSOLIDATED_SCRIPTS_GUIDE.md)** for the complete new interface.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start - Consolidated Scripts](#quick-start---consolidated-scripts)
3. [Multi-User Workshop Deployment](#multi-user-workshop-deployment)
4. [Single-User Deployment](#single-user-deployment)
5. [Legacy Scripts (Deprecated)](#legacy-scripts-deprecated)
6. [Additional Resources](#additional-resources)

## Prerequisites

### Required Tools
- **Optional Deploy OpenShift on RHPDS**
  - Red Hat OpenShift Container Platform Cluster (AWS)
  
- **OpenShift CLI (oc)**: Version 4.14+
  ```bash
  # Download from: https://mirror.openshift.com/pub/openshift-v4/clients/ocp/
  oc version
  ```

- **Helm**: Version 3.8+
  ```bash
  # Install from: https://helm.sh/docs/intro/install/
  helm version
  ```

- **Git**: For cloning the repository
  ```bash
  git --version
  ```

### Cluster Requirements

- **OpenShift**: Version 4.14+ (recommended 4.18+)
- **Resources**: Minimum 4 CPU cores, 8GB RAM per workshop instance
- **Storage**: Dynamic storage provisioning enabled
- **Operators**: OpenShift Dev Spaces operator (will be installed if needed)
- **Access**: Cluster admin permissions required for multi-user deployments
- **Network**: Ingress controller configured with wildcard DNS

## Quick Start - Consolidated Scripts

The new consolidated script system provides a unified interface for all deployment scenarios:

### Multi-User Workshop (Instructors)

```bash
# 1. Setup cluster prerequisites (one-time)
./scripts/deploy-workshop.sh --cluster-setup

# 2. Deploy workshop for 20 users
./scripts/deploy-workshop.sh --workshop --count 20

# 3. Test the deployment
./scripts/deploy-workshop.sh --test --workshop --count 20

# 4. Generate access URLs
./scripts/deploy-workshop.sh --workshop --generate-urls --count 20
```

### Single-User Deployment (Individual Developers)

```bash
# 1. Deploy personal environment
./scripts/deploy-workshop.sh --single-user --namespace my-workshop

# 2. Test deployment
./scripts/deploy-workshop.sh --test --single-user

# 3. Cleanup when done
./scripts/deploy-workshop.sh --single-user --cleanup --namespace my-workshop
```

## Legacy Quick Start - Red Hat Workshop Cluster

> **⚠️ Deprecated**: The following instructions use legacy scripts. Use the consolidated scripts above for new deployments.

For the specific Red Hat workshop cluster mentioned in the PRD:

### 1. Clone the Repository

```bash
git clone https://github.com/jeremyrdavis/dddhexagonalworkshop.git
cd dddhexagonalworkshop
```

### 2. Deploy to Red Hat Cluster

```bash
# Make scripts executable
chmod +x scripts/*.sh

# Deploy to the Red Hat workshop cluster
./scripts/deploy-to-redhat-cluster.sh
```

This script will:
- Login to the Red Hat workshop cluster
- Check cluster capabilities
- Install required operators
- Configure OpenShift Dev Spaces
- Deploy the workshop infrastructure
- Display access information

### 3. Access the Workshop

After deployment, you'll see output similar to:
```
🚀 OpenShift Dev Spaces: https://devspaces.apps.<cluster-domain>
📱 Workshop Application: https://ddd-workshop-quarkus-ddd-workshop.apps.<cluster-domain>
```

## Multi-User Workshop Deployment

This section provides comprehensive instructions for deploying the DDD Hexagonal Architecture Workshop for multiple users on a blank OpenShift cluster. This is ideal for workshop facilitators who need to set up environments for 10-50 participants.

### Overview

The multi-user deployment uses **two main scripts**:

1. **`create-workshop-users.sh`**: Creates HTPasswd users and namespaces
   - Creates OpenShift users with HTPasswd authentication
   - Creates user-specific namespaces (`user1-devspaces`, `user2-devspaces`, etc.)
   - Sets up RBAC and resource quotas
   - Uses positional parameters: `./scripts/create-workshop-users.sh [USER_PREFIX] [NUM_USERS] [PASSWORD]`

2. **`deploy-multi-user-workshop.sh`**: Deploys workshop environments
   - Deploys DevWorkspaces and workshop infrastructure
   - Supports multiple input methods (files, counts, lists)
   - Uses flag-based parameters: `--users-file`, `--count`, `--users`

### What Gets Created

The multi-user deployment creates:
- **HTPasswd users** in OpenShift authentication
- **User namespaces** with pattern `{username}-devspaces`
- **DevWorkspaces** for each user with complete development environment
- **Resource quotas** and limits per user namespace
- **RBAC** with proper permissions for workshop activities

### Multi-User Resource Requirements

#### Capacity Planning
| Users | CPU Cores | Memory | Storage | Notes |
|-------|-----------|--------|---------|-------|
| **10 users** | 24 cores | 48Gi | 200Gi | Small workshop |
| **20 users** | 44 cores | 88Gi | 400Gi | Medium workshop |
| **30 users** | 64 cores | 128Gi | 600Gi | Large workshop |

**Per User Requirements:**
- **CPU**: 2 cores + 4 cores for operators
- **Memory**: 4Gi + 8Gi for operators
- **Storage**: 20Gi for persistent volumes

### Step 1: Prepare the Cluster

#### 1.1 Login as Cluster Admin
```bash
# Login with cluster admin privileges
oc login --token=<admin-token> --server=<cluster-api-url>

# Verify admin access
oc auth can-i '*' '*' --all-namespaces
```

#### 1.2 Clone Workshop Repository
```bash
git clone https://github.com/tosin2013/dddhexagonalworkshop.git
cd dddhexagonalworkshop
chmod +x scripts/*.sh
```

#### 1.3 Install OpenShift Dev Spaces Operator
```bash
# Install Dev Spaces operator cluster-wide
./scripts/setup-cluster-devspaces.sh

# Verify operator installation
oc get csv -n openshift-operators | grep devspaces
```

### Step 2: Create User Infrastructure

#### 2.1 Create Workshop Users
The script uses positional parameters to create users:

```bash
# Basic usage: ./scripts/create-workshop-users.sh [USER_PREFIX] [NUM_USERS] [PASSWORD]

# Create 5 users (user1-user5) with default password
./scripts/create-workshop-users.sh user 5 workshop123

# Create 20 users (user1-user20) with custom password
./scripts/create-workshop-users.sh user 20 mypassword

# Create users with different prefix (student1-student10)
./scripts/create-workshop-users.sh student 10 workshop123
```

#### 2.2 What the Script Creates
This script creates:
- **HTPasswd Authentication**: Users in OpenShift's htpasswd identity provider
- **User namespaces**: `user1-devspaces`, `user2-devspaces`, etc.
- **Resource quotas**: CPU, memory, and storage limits per user namespace
- **RBAC**: Service accounts, roles, and role bindings for each user
- **Workshop labels**: Proper labeling for workshop management

#### 2.3 Verify User Infrastructure
```bash
# Check all user namespaces (actual naming pattern)
oc get namespaces | grep devspaces

# Verify resource quotas
oc get resourcequota -A | grep ddd-workshop

# Check RBAC for a specific user
oc get rolebindings -n user1-devspaces

# List all workshop users
oc get users | grep user
```

### Step 3: Deploy Workshop Environments

#### 3.1 Deploy Individual User Workspaces
```bash
# Deploy complete workshop environment for all users
./scripts/deploy-multi-user-workshop.sh --users-file users.txt

# Or deploy for specific number of users
./scripts/deploy-multi-user-workshop.sh --count 20

# Or deploy for specific users
./scripts/deploy-multi-user-workshop.sh --users "user1,user2,user3"

# Dry run to see what would be created
./scripts/deploy-multi-user-workshop.sh --dry-run --count 5
```

#### 3.2 Verify Workspace Deployment
```bash
# Check workspace status
oc get devworkspace -A | grep ddd-workshop

# Monitor workspace startup (basic monitoring)
watch 'oc get devworkspace -A | grep ddd-workshop'

# Check workspace events
oc get events -A | grep devworkspace

# Check specific user workspace
oc get devworkspace -n user1-devspaces
```

### Step 4: User Access and URLs

#### 4.1 Generate User Access Information
```bash
# Generate access URLs for all users
./scripts/deploy-multi-user-workshop.sh --generate-urls --users-file users.txt

# Or generate URLs for specific count
./scripts/deploy-multi-user-workshop.sh --generate-urls --count 20

# The create-workshop-users.sh script also displays access information
./scripts/create-workshop-users.sh user 20 workshop123
```

#### 4.2 User Access Pattern
Each user gets access to Dev Spaces with their credentials:
```
# Dev Spaces URL (shared for all users)
https://devspaces.apps.<cluster-domain>

# User credentials (created by create-workshop-users.sh)
Username: user1, user2, user3, etc.
Password: workshop123 (or custom password)

# Repository URL for workspace creation
https://github.com/tosin2013/dddhexagonalworkshop.git

# User namespaces (created automatically)
user1-devspaces, user2-devspaces, etc.
```

### Step 5: Workshop Management

#### 5.1 Monitor All Users
```bash
# Check all workspace status
oc get devworkspace -A | grep ddd-workshop

# View resource usage
oc adm top nodes
oc adm top pods -A | grep devspaces

# Monitor workspace health
watch 'oc get devworkspace -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,PHASE:.status.phase,STARTED:.spec.started'

# Check user namespaces
oc get namespaces | grep devspaces
```

#### 5.2 User Support Commands
```bash
# Restart specific user workspace (check actual workspace name first)
oc get devworkspace -n user5-devspaces
oc delete devworkspace <workspace-name> -n user5-devspaces

# Check user logs
oc logs -f deployment/devworkspace-controller -n openshift-devspaces

# Reset user environment by deleting and recreating workspace
oc delete devworkspace <workspace-name> -n user5-devspaces
./scripts/deploy-multi-user-workshop.sh --users "user5"
```

### Step 6: Scaling and Management

#### 6.1 Add More Users During Workshop
```bash
# Add additional users using create-workshop-users.sh
# Note: This will add to existing htpasswd, but you need to specify total count
./scripts/create-workshop-users.sh user 25 workshop123  # Creates user1-user25

# Then deploy workspaces for new users
./scripts/deploy-multi-user-workshop.sh --users "user21,user22,user23,user24,user25"

# Or use incremental deployment
./scripts/deploy-multi-user-workshop.sh --incremental --count 25
```

#### 6.2 Resource Monitoring
```bash
# Monitor cluster resources
watch 'oc adm top nodes && echo "---" && oc adm top pods -A | grep devspaces | head -10'

# Check resource quotas for user namespaces
oc get resourcequota -A | grep ddd-workshop

# Detailed resource quota view
oc get resourcequota -A -o custom-columns=NAMESPACE:.metadata.namespace,CPU-USED:.status.used.cpu,CPU-LIMIT:.status.hard.cpu,MEMORY-USED:.status.used.memory,MEMORY-LIMIT:.status.hard.memory | grep devspaces
```

### Step 7: Workshop Cleanup

#### 7.1 Clean Up User Environments
```bash
# Remove all user workspaces using deploy script
./scripts/deploy-multi-user-workshop.sh --cleanup --users-file users.txt

# Or remove specific users
./scripts/deploy-multi-user-workshop.sh --cleanup --users "user1,user2,user3"

# Note: create-workshop-users.sh doesn't have cleanup flags
# You need to manually remove users from htpasswd if needed
```

#### 7.2 Complete Cleanup
```bash
# Remove all workshop user namespaces (correct pattern)
for ns in $(oc get ns | grep '\-devspaces' | awk '{print $1}'); do
  oc delete namespace $ns
done

# Remove users from htpasswd (manual process)
# oc get secret htpasswd -n openshift-config -o jsonpath='{.data.htpasswd}' | base64 -d > /tmp/htpasswd
# Edit /tmp/htpasswd to remove users
# oc create secret generic htpasswd --from-file=htpasswd=/tmp/htpasswd --dry-run=client -o yaml | oc replace -f - -n openshift-config

# Remove Dev Spaces operator (optional)
oc delete subscription devspaces -n openshift-operators
oc delete csv $(oc get csv -n openshift-operators | grep devspaces | awk '{print $1}') -n openshift-operators
```

### Troubleshooting Multi-User Deployment

#### Common Issues

**1. Resource Exhaustion**
```bash
# Check node resources
oc describe nodes | grep -A 5 "Allocated resources"

# Adjust resource quotas
oc patch resourcequota user-quota -n ddd-workshop-user1 --patch '{"spec":{"hard":{"requests.memory":"2Gi"}}}'
```

**2. Workspace Startup Failures**
```bash
# Check workspace events (use correct namespace pattern)
oc get events -n user1-devspaces --sort-by='.lastTimestamp'

# List workspaces in user namespace
oc get devworkspace -n user1-devspaces

# Restart workspace (get actual workspace name first)
oc delete devworkspace <workspace-name> -n user1-devspaces
```

**3. Network Connectivity Issues**
```bash
# Check network policies
oc get networkpolicy -A | grep ddd-workshop

# Test connectivity between services
oc exec -it <pod-name> -n user1-devspaces -- nc -zv localhost 5432
```

### Best Practices for Multi-User Workshops

#### Resource Management
- **Start Small**: Begin with 5-10 users to test capacity
- **Monitor Continuously**: Watch resource usage during workshop
- **Have Spare Capacity**: Plan for 20% overhead
- **Use Resource Quotas**: Prevent any single user from consuming too many resources

#### User Experience
- **Pre-deploy Environments**: Create all workspaces before workshop starts
- **Test User Access**: Verify at least 3 user environments work completely
- **Prepare Support Scripts**: Have troubleshooting commands ready
- **Document User URLs**: Provide clear access instructions

#### Workshop Delivery
- **Stagger Startup**: Don't have all users start simultaneously
- **Monitor Health**: Check workspace status every 15 minutes
- **Have Backup Plan**: Prepare alternative access methods
- **Collect Feedback**: Gather user experience data for improvements

---

## Additional Resources

For production application deployment (non-workshop), see [PRODUCTION_DEPLOYMENT.md](PRODUCTION_DEPLOYMENT.md).

**Author**: Tosin Akinsoho <takinosh@redhat.com>
**Repository**: https://github.com/jeremyrdavis/dddhexagonalworkshop
**Focus**: Multi-User Workshop Deployment and Management


