# Production OpenShift Deployment Guide
## DDD Hexagonal Architecture Application

This guide provides instructions for deploying the DDD Hexagonal Architecture application to OpenShift clusters for production, staging, and development environments using Helm charts.

> **Note**: This guide is for **application deployment**, not workshop facilitation. 
> For workshop deployment, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [General OpenShift Deployment](#general-openshift-deployment)
3. [Environment Configurations](#environment-configurations)
4. [Helm Chart Customization](#helm-chart-customization)
5. [OpenShift Dev Spaces Integration](#openshift-dev-spaces-integration)
6. [Troubleshooting](#troubleshooting)
7. [Cleanup](#cleanup)
8. [Advanced Configuration](#advanced-configuration)

## Prerequisites

### Required Tools
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
- **Resources**: Minimum 2 CPU cores, 4GB RAM per application instance
- **Storage**: Dynamic storage provisioning enabled
- **Access**: Namespace admin permissions required
- **Network**: Ingress controller configured

## General OpenShift Deployment

For deploying the DDD application to any OpenShift cluster:

### 1. Clone the Repository

```bash
git clone https://github.com/jeremyrdavis/dddhexagonalworkshop.git
cd dddhexagonalworkshop
```

### 2. Login to Your Cluster

```bash
# Login with token
oc login --token=<your-token> --server=<your-server>

# Or login with username/password
oc login <your-server>
```

### 3. Deploy Using Helm

```bash
# Deploy to development environment
./scripts/deploy-to-openshift.sh --namespace ddd-workshop --environment dev

# Deploy to staging environment
./scripts/deploy-to-openshift.sh --namespace ddd-workshop-staging --environment staging

# Deploy to production environment
./scripts/deploy-to-openshift.sh --namespace ddd-workshop-prod --environment prod
```

### 4. Verify Deployment

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
  namespace: my-ddd-app
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
  host: my-ddd-app.apps.mycluster.com
```

Deploy with custom values:
```bash
helm install ddd-app helm/ddd-workshop \
  --namespace my-ddd-app \
  --values custom-values.yaml
```

### Environment Variables

Key environment variables for customization:

```bash
export NAMESPACE="my-ddd-app"
export ENVIRONMENT="staging"
export RELEASE_NAME="my-ddd-app"

./scripts/deploy-to-openshift.sh
```

## OpenShift Dev Spaces Integration

### Automatic Configuration

The deployment automatically configures OpenShift Dev Spaces with:

- **DevWorkspace**: Pre-configured workspace template
- **Container Images**: Red Hat certified images
- **Resource Limits**: Environment-appropriate limits
- **Networking**: Internal service discovery
- **Volumes**: Ephemeral storage for application data

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

### Remove Application Deployment

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
# Remove all application resources
oc delete namespace ddd-workshop ddd-workshop-staging ddd-workshop-prod

# Remove Dev Spaces (if no longer needed)
oc delete checluster devspaces -n openshift-devspaces
```

## Advanced Configuration

### Multi-Tenant Deployment

For multiple application instances:

```bash
# Deploy multiple instances
for i in {1..5}; do
  ./scripts/deploy-to-openshift.sh \
    --namespace "ddd-app-team-$i" \
    --release-name "ddd-app-team-$i"
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

For production deployment issues and questions:

- **Repository**: https://github.com/jeremyrdavis/dddhexagonalworkshop
- **Author**: Tosin Akinsoho <takinosh@redhat.com>
- **Documentation**: Check the `docs/` directory for additional guides

---

**Note**: This guide focuses on production application deployment. For workshop facilitation and multi-user environments, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).
