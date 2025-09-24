#!/bin/bash
# OpenShift Workshop Cluster Deployment Script
# This script deploys to an OpenShift cluster for workshop delivery

set -e

# Cluster Configuration (set these environment variables or update here)
CLUSTER_SERVER="${CLUSTER_SERVER:-https://api.cluster-6lwnl.6lwnl.sandbox1592.opentlc.com:6443}"
CLUSTER_TOKEN="${CLUSTER_TOKEN:-sha256~3EKmx_JOIpbRxckQoJrSqVSg7nnWn9n58nUT2CRQOco}"

# Script configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to login to Red Hat cluster
login_to_cluster() {
    log_step "Logging in to Red Hat workshop cluster..."
    
    # Check if already logged in to the correct cluster
    if oc whoami --show-server 2>/dev/null | grep -q "$CLUSTER_SERVER"; then
        log_info "Already logged in to the correct cluster"
        log_info "Current user: $(oc whoami)"
        return 0
    fi
    
    log_info "Logging in to cluster: $CLUSTER_SERVER"
    
    # Login with token
    if oc login --token="$CLUSTER_TOKEN" --server="$CLUSTER_SERVER" --insecure-skip-tls-verify=true; then
        log_info "✅ Successfully logged in to Red Hat workshop cluster"
        log_info "Current user: $(oc whoami)"
        log_info "Current server: $(oc whoami --show-server)"
    else
        log_error "❌ Failed to login to Red Hat workshop cluster"
        log_error "Please check the token and server URL"
        exit 1
    fi
}

# Function to check cluster capabilities
check_cluster_capabilities() {
    log_step "Checking cluster capabilities..."
    
    # Check OpenShift version
    local ocp_version
    ocp_version=$(oc version -o json | jq -r '.openshiftVersion // "unknown"')
    log_info "OpenShift version: $ocp_version"
    
    # Check if OpenShift Dev Spaces operator is available
    if oc get csv -A | grep -q "devspaces"; then
        log_info "✅ OpenShift Dev Spaces operator is available"
    else
        log_warn "⚠️  OpenShift Dev Spaces operator not found"
        log_info "You may need to install the operator first"
    fi
    
    # Check available storage classes
    log_info "Available storage classes:"
    oc get storageclass --no-headers | awk '{print "  - " $1}' || log_warn "Could not retrieve storage classes"
    
    # Check node resources
    log_info "Cluster node information:"
    oc get nodes -o custom-columns="NAME:.metadata.name,CPU:.status.capacity.cpu,MEMORY:.status.capacity.memory" --no-headers | while read -r line; do
        echo "  - $line"
    done
}

# Function to create workshop namespace with proper configuration
create_workshop_namespace() {
    local namespace="$1"
    
    log_step "Creating workshop namespace: $namespace"
    
    # Create namespace if it doesn't exist
    if oc get namespace "$namespace" >/dev/null 2>&1; then
        log_info "Namespace $namespace already exists"
    else
        log_info "Creating namespace: $namespace"
        oc create namespace "$namespace"
    fi
    
    # Add Red Hat workshop specific labels
    oc label namespace "$namespace" \
        app.kubernetes.io/name=ddd-workshop \
        app.kubernetes.io/part-of=ddd-workshop \
        workshop.redhat.com/type=ddd-hexagonal \
        workshop.redhat.com/cluster=pwz5r \
        --overwrite
    
    # Add annotations for workshop metadata
    oc annotate namespace "$namespace" \
        workshop.redhat.com/description="DDD Hexagonal Architecture Workshop" \
        workshop.redhat.com/author="Tosin Akinsoho <takinosh@redhat.com>" \
        workshop.redhat.com/repository="https://github.com/jeremyrdavis/dddhexagonalworkshop.git" \
        --overwrite
    
    # Switch to the namespace
    oc project "$namespace"
    log_info "✅ Using namespace: $namespace"
}

# Function to install required operators
install_operators() {
    log_step "Checking and installing required operators..."
    
    # Check if we have cluster-admin privileges
    if oc auth can-i create clusterroles >/dev/null 2>&1; then
        log_info "✅ Have cluster-admin privileges"
        
        # Install OpenShift Dev Spaces operator if not present
        if ! oc get csv -A | grep -q "devspaces"; then
            log_info "Installing OpenShift Dev Spaces operator..."
            
            cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: devspaces
  namespace: openshift-operators
spec:
  channel: stable
  installPlanApproval: Automatic
  name: devspaces
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
            
            log_info "Waiting for OpenShift Dev Spaces operator to be ready..."
            oc wait --for=condition=AtLatestKnown subscription/devspaces -n openshift-operators --timeout=300s
        else
            log_info "✅ OpenShift Dev Spaces operator is already installed"
        fi
    else
        log_warn "⚠️  No cluster-admin privileges, skipping operator installation"
        log_info "Please ensure OpenShift Dev Spaces operator is installed"
    fi
}

# Function to configure Dev Spaces CheCluster
configure_dev_spaces() {
    local namespace="$1"
    
    log_step "Configuring OpenShift Dev Spaces..."
    
    # Check if CheCluster exists
    if oc get checluster -A >/dev/null 2>&1; then
        log_info "✅ OpenShift Dev Spaces is already configured"
        return 0
    fi
    
    # Create CheCluster configuration
    log_info "Creating CheCluster configuration..."
    
    cat <<EOF | oc apply -f -
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
    metrics:
      enable: true
  containerRegistry: {}
  devEnvironments:
    startTimeoutSeconds: 600
    secondsOfRunBeforeIdling: 1800
    maxNumberOfWorkspacesPerUser: 5
    maxNumberOfRunningWorkspacesPerUser: 3
    containerBuildConfiguration:
      openShiftSecurityContextConstraint: container-build
    disableContainerBuildCapabilities: false
    defaultEditor: che-incubator/che-code/latest
    defaultNamespace:
      autoProvision: true
      template: <username>-devspaces
    secondsOfInactivityBeforeIdling: 1800
    storage:
      pvcStrategy: per-workspace
  gitServices: {}
  networking:
    auth:
      gateway:
        configLabels:
          app: che
          component: che-gateway-config
EOF
    
    log_info "Waiting for OpenShift Dev Spaces to be ready..."
    oc wait --for=condition=Available checluster/devspaces -n openshift-devspaces --timeout=600s
    
    log_info "✅ OpenShift Dev Spaces configured successfully"
}

# Function to deploy workshop with Red Hat specific configurations
deploy_workshop() {
    local namespace="$1"
    local environment="${2:-dev}"
    
    log_step "Deploying DDD Hexagonal Workshop..."
    
    # Set Red Hat specific environment variables
    export NAMESPACE="$namespace"
    export ENVIRONMENT="$environment"
    export RELEASE_NAME="ddd-workshop"
    
    # Use the main deployment script with Red Hat specific configurations
    "$SCRIPT_DIR/deploy-to-openshift.sh" deploy
}

# Function to create workshop user accounts (if needed)
create_workshop_users() {
    local namespace="$1"
    local user_count="${2:-10}"
    
    log_step "Creating workshop user accounts..."
    
    if ! oc auth can-i create users >/dev/null 2>&1; then
        log_warn "⚠️  No privileges to create users, skipping user creation"
        return 0
    fi
    
    for i in $(seq 1 "$user_count"); do
        local username="workshop-user-$(printf "%02d" "$i")"
        
        if oc get user "$username" >/dev/null 2>&1; then
            log_info "User $username already exists"
        else
            log_info "Creating user: $username"
            
            # Create user
            cat <<EOF | oc apply -f -
apiVersion: user.openshift.io/v1
kind: User
metadata:
  name: $username
identities:
- htpasswd_provider:$username
EOF
            
            # Create identity
            cat <<EOF | oc apply -f -
apiVersion: user.openshift.io/v1
kind: Identity
metadata:
  name: htpasswd_provider:$username
providerName: htpasswd_provider
providerUserName: $username
user:
  name: $username
  uid: $(oc get user $username -o jsonpath='{.metadata.uid}')
EOF
        fi
        
        # Grant access to workshop namespace
        oc adm policy add-role-to-user edit "$username" -n "$namespace"
    done
    
    log_info "✅ Workshop users created and configured"
}

# Function to display Red Hat cluster specific information
display_cluster_info() {
    local namespace="$1"
    
    log_step "Red Hat Workshop Cluster Information"
    echo "=================================="
    echo "🏢 Cluster: Red Hat Dynamic Workshop"
    echo "🌐 Server: $CLUSTER_SERVER"
    echo "👤 Current User: $(oc whoami)"
    echo "📦 Namespace: $namespace"
    echo "🔧 OpenShift Version: $(oc version -o json | jq -r '.openshiftVersion // "unknown"')"
    echo ""
    
    # Get Dev Spaces URL if available
    if oc get checluster -A >/dev/null 2>&1; then
        local devspaces_url
        devspaces_url=$(oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}' 2>/dev/null || echo "")
        if [ -n "$devspaces_url" ]; then
            echo "🚀 OpenShift Dev Spaces: $devspaces_url"
        fi
    fi
    
    # Get workshop application URL
    if oc get routes -n "$namespace" -l app.kubernetes.io/name=ddd-workshop >/dev/null 2>&1; then
        local app_url
        app_url=$(oc get route ddd-workshop-quarkus -n "$namespace" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
        if [ -n "$app_url" ]; then
            echo "📱 Workshop Application: https://$app_url"
        fi
    fi
    
    echo ""
    echo "📋 Next Steps:"
    echo "1. Access OpenShift Dev Spaces and create a new workspace"
    echo "2. Use the repository: https://github.com/tosin2013/dddhexagonalworkshop.git"
    echo "3. The devfile.yaml will automatically configure the workshop environment"
    echo "4. Start with Module 01: End-to-End DDD"
    echo "=================================="
}

# Main function
main() {
    local namespace="${1:-ddd-workshop}"
    local environment="${2:-dev}"
    
    log_info "🚀 Starting Red Hat Workshop Cluster Deployment"
    log_info "Target cluster: $CLUSTER_SERVER"
    log_info "Namespace: $namespace"
    log_info "Environment: $environment"
    echo ""
    
    login_to_cluster
    echo ""
    
    check_cluster_capabilities
    echo ""
    
    create_workshop_namespace "$namespace"
    echo ""
    
    install_operators
    echo ""
    
    configure_dev_spaces "$namespace"
    echo ""
    
    deploy_workshop "$namespace" "$environment"
    echo ""
    
    display_cluster_info "$namespace"
    
    log_info "🎉 Red Hat workshop cluster deployment completed successfully!"
    log_info "Workshop is ready for participants!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Red Hat Workshop Cluster Deployment Script"
        echo ""
        echo "Usage: $0 [NAMESPACE] [ENVIRONMENT]"
        echo ""
        echo "Arguments:"
        echo "  NAMESPACE              Target namespace (default: ddd-workshop)"
        echo "  ENVIRONMENT            Environment (dev/staging/prod, default: dev)"
        echo ""
        echo "Commands:"
        echo "  --help, -h             Show this help message"
        echo "  --login-only           Only login to the cluster"
        echo "  --check-only           Only check cluster capabilities"
        echo "  --create-users N       Create N workshop users (default: 10)"
        echo ""
        echo "Examples:"
        echo "  $0                                    # Deploy to ddd-workshop namespace"
        echo "  $0 my-workshop staging               # Deploy to my-workshop namespace with staging config"
        echo "  $0 --create-users 20                 # Create 20 workshop users"
        exit 0
        ;;
    --login-only)
        login_to_cluster
        exit 0
        ;;
    --check-only)
        login_to_cluster
        check_cluster_capabilities
        exit 0
        ;;
    --create-users)
        local user_count="${2:-10}"
        login_to_cluster
        create_workshop_users "ddd-workshop" "$user_count"
        exit 0
        ;;
esac

# Run main function with arguments
main "$@"
