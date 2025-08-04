# OpenShift Deployment Guide
## DDD Hexagonal Architecture Workshop

This guide provides comprehensive instructions for deploying the DDD Hexagonal Architecture Workshop to OpenShift clusters using Helm charts and OpenShift Dev Spaces.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start - Red Hat Workshop Cluster](#quick-start---red-hat-workshop-cluster)
3. [Multi-User Workshop Deployment](#multi-user-workshop-deployment)
4. [General OpenShift Deployment](#general-openshift-deployment)
5. [Environment Configurations](#environment-configurations)
6. [Troubleshooting](#troubleshooting)
7. [Advanced Configuration](#advanced-configuration)

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

## Quick Start - Red Hat Workshop Cluster

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

The multi-user deployment creates:
- **OpenShift Dev Spaces operator** for cloud-native development environments
- **Individual user namespaces** with isolated resources
- **Complete workshop environments** with Java 21, PostgreSQL, and Kafka
- **User management** and access control
- **Resource quotas** and limits per user

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

#### 2.1 Generate User List
Create a user list file with workshop participants:

```bash
# Create users.txt with one username per line
cat > users.txt << 'EOF'
user1
user2
user3
user4
user5
user10
user15
user20
EOF
```

#### 2.2 Deploy User Infrastructure
```bash
# Deploy infrastructure for all users
./scripts/create-workshop-users.sh --users-file users.txt

# Or deploy for specific number of users
./scripts/create-workshop-users.sh --count 20
```

This script creates:
- **User namespaces**: `ddd-workshop-user1`, `ddd-workshop-user2`, etc.
- **Resource quotas**: CPU, memory, and storage limits per user
- **RBAC**: Proper permissions for each user
- **Network policies**: Isolation between user environments

#### 2.3 Verify User Infrastructure
```bash
# Check all user namespaces
oc get namespaces | grep ddd-workshop-user

# Verify resource quotas
oc get resourcequota -A | grep ddd-workshop

# Check RBAC
oc get rolebindings -n ddd-workshop-user1
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
```

#### 3.2 Verify Workspace Deployment
```bash
# Check workspace status
oc get devworkspace -A | grep ddd-workshop

# Monitor workspace startup (basic monitoring)
watch 'oc get devworkspace -A | grep ddd-workshop'

# Check workspace events
oc get events -A | grep devworkspace
```

### Step 4: User Access and URLs

#### 4.1 Generate User Access Information
```bash
# Generate access URLs for all users
./scripts/deploy-multi-user-workshop.sh --generate-urls --users-file users.txt

# Or generate URLs for specific count
./scripts/deploy-multi-user-workshop.sh --generate-urls --count 20
```

#### 4.2 User Access Pattern
Each user gets a unique Dev Spaces URL:
```
# User-specific Dev Spaces URLs
https://devspaces.apps.<cluster-domain>/#https://github.com/tosin2013/dddhexagonalworkshop.git&devfilePath=devfile-complete.yaml

# User credentials (if using HTPasswd)
Username: user1, user2, user3, etc.
Password: <workshop-password>
```

### Step 5: Workshop Management

#### 5.1 Monitor All Users
```bash
# Check all workspace status
oc get devworkspace -A | grep ddd-workshop

# View resource usage
oc adm top nodes
oc adm top pods -A | grep ddd-workshop

# Monitor workspace health
watch 'oc get devworkspace -A -o custom-columns=NAME:.metadata.name,NAMESPACE:.metadata.namespace,PHASE:.status.phase,STARTED:.spec.started'
```

#### 5.2 User Support Commands
```bash
# Restart specific user workspace
oc delete devworkspace ddd-workshop-user5 -n ddd-workshop-user5

# Check user logs
oc logs -f deployment/devworkspace-controller -n openshift-devspaces

# Reset user environment by deleting and recreating workspace
oc delete devworkspace ddd-workshop-user5 -n ddd-workshop-user5
./scripts/deploy-multi-user-workshop.sh --users "user5"
```

### Step 6: Scaling and Management

#### 6.1 Add More Users During Workshop
```bash
# Add additional users
echo -e "user21\nuser22\nuser23" >> users.txt
./scripts/create-workshop-users.sh --users-file users.txt --incremental
```

#### 6.2 Resource Monitoring
```bash
# Monitor cluster resources
watch 'oc adm top nodes && echo "---" && oc adm top pods -A | grep ddd-workshop | head -10'

# Check resource quotas
oc get resourcequota -A -o custom-columns=NAMESPACE:.metadata.namespace,CPU-USED:.status.used.cpu,CPU-LIMIT:.status.hard.cpu,MEMORY-USED:.status.used.memory,MEMORY-LIMIT:.status.hard.memory
```

### Step 7: Workshop Cleanup

#### 7.1 Clean Up User Environments
```bash
# Remove all user workspaces
./scripts/create-workshop-users.sh --cleanup --users-file users.txt

# Or remove specific users
./scripts/create-workshop-users.sh --cleanup --users "user1,user2,user3"
```

#### 7.2 Complete Cleanup
```bash
# Remove all workshop resources
for ns in $(oc get ns | grep ddd-workshop-user | awk '{print $1}'); do
  oc delete namespace $ns
done

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
# Check workspace events
oc get events -n ddd-workshop-user1 --sort-by='.lastTimestamp'

# Restart workspace
oc delete devworkspace ddd-workshop-user1 -n ddd-workshop-user1
```

**3. Network Connectivity Issues**
```bash
# Check network policies
oc get networkpolicy -A | grep ddd-workshop

# Test connectivity between services
oc exec -it <pod-name> -n ddd-workshop-user1 -- nc -zv localhost 5432
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

## General OpenShift Deployment

For deploying to any OpenShift cluster:

### 1. Login to Your Cluster

```bash
# Login with token
oc login --token=<your-token> --server=<your-server>

# Or login with username/password
oc login <your-server>
```

### 2. Deploy Using Helm

```bash
# Deploy to development environment
./scripts/deploy-to-openshift.sh --namespace ddd-workshop --environment dev

# Deploy to staging environment
./scripts/deploy-to-openshift.sh --namespace ddd-workshop-staging --environment staging

# Deploy to production environment
./scripts/deploy-to-openshift.sh --namespace ddd-workshop-prod --environment prod
```

### 3. Verify Deployment

```bash
# Check deployment status
./scripts/deploy-to-openshift.sh verify --namespace ddd-workshop

# Run post-deployment tests
./scripts/deploy-to-openshift.sh test --namespace ddd-workshop
```

## Environment Configurations

### Development Environment

- **Resource Limits**: Reduced for development
- **Debug Ports**: Enabled
- **Security**: Relaxed constraints
- **Storage**: Ephemeral

```bash
./scripts/deploy-to-openshift.sh --environment dev
```

### Staging Environment

- **Resource Limits**: Production-like
- **Monitoring**: Enabled
- **Security**: Standard constraints
- **Storage**: Persistent (optional)

```bash
./scripts/deploy-to-openshift.sh --environment staging
```

### Production Environment

- **Resource Limits**: Full production resources
- **Monitoring**: Full observability stack
- **Security**: Strict constraints
- **Storage**: Persistent
- **Autoscaling**: Enabled

```bash
./scripts/deploy-to-openshift.sh --environment prod
```

## Helm Chart Customization

### Custom Values File

Create a custom values file for your environment:

```yaml
# custom-values.yaml
global:
  namespace: my-workshop
  imageRegistry: my-registry.com

postgresql:
  resources:
    limits:
      memory: 1Gi
      cpu: 500m

quarkus:
  resources:
    limits:
      memory: 2Gi
      cpu: 1000m

route:
  host: my-workshop.apps.mycluster.com
```

Deploy with custom values:
```bash
helm install ddd-workshop helm/ddd-workshop \
  --namespace my-workshop \
  --values custom-values.yaml
```

### Environment Variables

Key environment variables for customization:

```bash
export NAMESPACE="my-workshop"
export ENVIRONMENT="staging"
export RELEASE_NAME="my-ddd-workshop"

./scripts/deploy-to-openshift.sh
```

## OpenShift Dev Spaces Integration

### Automatic Configuration

The deployment automatically configures OpenShift Dev Spaces with:

- **DevWorkspace**: Pre-configured workspace template
- **Container Images**: Red Hat certified images
- **Resource Limits**: Environment-appropriate limits
- **Networking**: Internal service discovery
- **Volumes**: Ephemeral storage for workshop data

### Manual Dev Spaces Setup

If you need to manually configure Dev Spaces:

1. **Install Dev Spaces Operator**:
   ```bash
   oc apply -f - <<EOF
   apiVersion: operators.coreos.com/v1alpha1
   kind: Subscription
   metadata:
     name: devspaces
     namespace: openshift-operators
   spec:
     channel: stable
     name: devspaces
     source: redhat-operators
     sourceNamespace: openshift-marketplace
   EOF
   ```

2. **Create CheCluster**:
   ```bash
   oc apply -f - <<EOF
   apiVersion: org.eclipse.che/v2
   kind: CheCluster
   metadata:
     name: devspaces
     namespace: openshift-devspaces
   spec:
     components:
       cheServer:
         debug: false
         logLevel: INFO
     devEnvironments:
       startTimeoutSeconds: 600
       maxNumberOfWorkspacesPerUser: 5
   EOF
   ```

## Troubleshooting

### Common Issues

#### 1. Deployment Fails

```bash
# Check pod status
oc get pods -n ddd-workshop

# Check pod logs
oc logs -f deployment/ddd-workshop-postgresql -n ddd-workshop

# Check events
oc get events -n ddd-workshop --sort-by='.lastTimestamp'
```

#### 2. Network Connectivity Issues

```bash
# Test service connectivity manually
timeout 3 bash -c '</dev/tcp/localhost/5432' && echo "PostgreSQL OK" || echo "PostgreSQL not accessible"
timeout 3 bash -c '</dev/tcp/localhost/9092' && echo "Kafka OK" || echo "Kafka not accessible"

# Check application health
curl -s http://localhost:8080/q/health || echo "Quarkus not running"

# Use health check scripts
./scripts/health-checks/postgresql-health.sh
./scripts/health-checks/kafka-health.sh
./scripts/health-checks/quarkus-health.sh
```

#### 3. Resource Constraints

```bash
# Check resource usage
oc top pods -n ddd-workshop

# Check resource quotas
oc describe resourcequota -n ddd-workshop

# Adjust resource limits in values file
```

#### 4. Storage Issues

```bash
# Check storage classes
oc get storageclass

# Check PVCs
oc get pvc -n ddd-workshop

# Check PV status
oc get pv
```

### Debug Commands

```bash
# Port forward to services
oc port-forward svc/ddd-workshop-postgresql 5432:5432 -n ddd-workshop
oc port-forward svc/ddd-workshop-kafka 9092:9092 -n ddd-workshop
oc port-forward svc/ddd-workshop-quarkus 8080:8080 -n ddd-workshop

# Execute commands in containers
oc exec -it deployment/ddd-workshop-postgresql -n ddd-workshop -- psql -U attendee -d conference
oc exec -it deployment/ddd-workshop-kafka -n ddd-workshop -- kafka-topics.sh --bootstrap-server localhost:9092 --list

# View detailed resource information
oc describe deployment ddd-workshop-quarkus -n ddd-workshop
oc describe service ddd-workshop-quarkus -n ddd-workshop
oc describe route ddd-workshop-quarkus -n ddd-workshop
```

## Cleanup

### Remove Workshop Deployment

```bash
# Using the deployment script
./scripts/deploy-to-openshift.sh cleanup --namespace ddd-workshop

# Using Helm directly
helm uninstall ddd-workshop -n ddd-workshop

# Delete namespace (optional)
oc delete namespace ddd-workshop
```

### Complete Cleanup

```bash
# Remove all workshop resources
oc delete namespace ddd-workshop ddd-workshop-staging ddd-workshop-prod

# Remove Dev Spaces (if no longer needed)
oc delete checluster devspaces -n openshift-devspaces
```

## Advanced Configuration

### Multi-Tenant Deployment

For multiple workshop instances:

```bash
# Deploy multiple instances
for i in {1..5}; do
  ./scripts/deploy-to-openshift.sh \
    --namespace "ddd-workshop-team-$i" \
    --release-name "ddd-workshop-team-$i"
done
```

### Custom Container Images

Update the Helm values to use custom images:

```yaml
postgresql:
  image: my-registry.com/postgresql-15:custom
kafka:
  image: my-registry.com/kafka:custom
quarkus:
  image: my-registry.com/openjdk-21:custom
```

### Monitoring Integration

Enable monitoring with Prometheus and Grafana:

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: 15s
```

## Support

For issues and questions:

- **Repository**: https://github.com/jeremyrdavis/dddhexagonalworkshop
- **Author**: Tosin Akinsoho <takinosh@redhat.com>
- **Documentation**: Check the `docs/` directory for additional guides
