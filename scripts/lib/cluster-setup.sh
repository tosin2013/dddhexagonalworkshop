#!/bin/bash
# Cluster Setup Library for DDD Hexagonal Workshop
# Handles OpenShift Dev Spaces installation and cluster configuration
# Consolidates functionality from setup-cluster-devspaces.sh and deploy-to-redhat-cluster.sh

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common-utils.sh
source "$SCRIPT_DIR/common-utils.sh"

# Configuration
readonly DEVSPACES_NAMESPACE="openshift-devspaces"
readonly DEVSPACES_OPERATOR_NAMESPACE="openshift-operators"
readonly CHECLUSTER_NAME="devspaces"

#######################################
# Dev Spaces Operator Installation
#######################################

# Install OpenShift Dev Spaces operator
install_devspaces_operator() {
    log_step "Installing OpenShift Dev Spaces operator..."
    log_confidence "92" "Dev Spaces operator installation process"
    
    # Check if operator is already installed
    if oc get csv -n "$DEVSPACES_OPERATOR_NAMESPACE" | grep -q devspaces; then
        log_info "OpenShift Dev Spaces operator already installed"
        return 0
    fi
    
    log_info "Creating Dev Spaces operator subscription..."
    
    # Create subscription for Dev Spaces operator
    cat <<EOF | oc apply -f -
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: devspaces
  namespace: $DEVSPACES_OPERATOR_NAMESPACE
spec:
  channel: stable
  installPlanApproval: Automatic
  name: devspaces
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF
    
    # Wait for operator to be installed
    log_info "Waiting for Dev Spaces operator installation..."
    local timeout=300
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if oc get csv -n "$DEVSPACES_OPERATOR_NAMESPACE" | grep -q "devspaces.*Succeeded"; then
            log_success "OpenShift Dev Spaces operator installed successfully"
            return 0
        fi
        
        echo -n "."
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    log_error "Timeout waiting for Dev Spaces operator installation"
    return 1
}

# Create CheCluster for multi-user support
create_checluster() {
    log_step "Creating CheCluster for multi-user support..."
    log_confidence "88" "CheCluster configuration"
    
    # Ensure Dev Spaces namespace exists
    create_namespace_with_labels "$DEVSPACES_NAMESPACE" \
        "app.kubernetes.io/name=devspaces" \
        "app.kubernetes.io/component=cluster-setup"
    
    # Check if CheCluster already exists
    if oc get checluster "$CHECLUSTER_NAME" -n "$DEVSPACES_NAMESPACE" >/dev/null 2>&1; then
        log_info "CheCluster already exists"
        return 0
    fi
    
    log_info "Creating CheCluster configuration..."
    
    # Create CheCluster with workshop-optimized settings
    cat <<EOF | oc apply -f -
apiVersion: org.eclipse.che/v2
kind: CheCluster
metadata:
  name: $CHECLUSTER_NAME
  namespace: $DEVSPACES_NAMESPACE
  labels:
    app.kubernetes.io/name: devspaces
    app.kubernetes.io/component: che-cluster
spec:
  components:
    cheServer:
      debug: false
      logLevel: INFO
    metrics:
      enable: true
    pluginRegistry:
      openVSXURL: https://open-vsx.org
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
    
    log_info "Waiting for CheCluster to be ready..."
    
    # Wait for CheCluster to be available
    local timeout=600
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        local phase
        phase=$(oc get checluster "$CHECLUSTER_NAME" -n "$DEVSPACES_NAMESPACE" -o jsonpath='{.status.chePhase}' 2>/dev/null || echo "")
        
        if [[ "$phase" == "Active" ]]; then
            log_success "CheCluster is active and ready"
            return 0
        elif [[ "$phase" == "Failed" ]]; then
            log_error "CheCluster deployment failed"
            oc get checluster "$CHECLUSTER_NAME" -n "$DEVSPACES_NAMESPACE" -o yaml
            return 1
        fi
        
        log_debug "CheCluster phase: $phase"
        echo -n "."
        sleep 15
        elapsed=$((elapsed + 15))
    done
    
    log_error "Timeout waiting for CheCluster to be ready"
    return 1
}

#######################################
# Cluster Configuration
#######################################

# Configure cluster for workshop requirements
configure_cluster_for_workshop() {
    log_step "Configuring cluster for workshop requirements..."
    log_confidence "85" "Cluster configuration process"
    
    # Check cluster resources
    check_cluster_resources 8 4 || log_warn "Cluster may have insufficient resources for large workshops"
    
    # Configure image registry (if needed)
    configure_image_registry
    
    # Configure monitoring (if needed)
    configure_monitoring
    
    log_success "Cluster configuration completed"
}

# Configure image registry for workshop
configure_image_registry() {
    log_debug "Checking image registry configuration..."
    
    # Check if image registry is available
    if oc get configs.imageregistry.operator.openshift.io cluster >/dev/null 2>&1; then
        local registry_state
        registry_state=$(oc get configs.imageregistry.operator.openshift.io cluster -o jsonpath='{.spec.managementState}')
        
        if [[ "$registry_state" != "Managed" ]]; then
            log_info "Image registry is not managed, workshop may have limited functionality"
        else
            log_debug "Image registry is properly configured"
        fi
    else
        log_warn "Image registry configuration not found"
    fi
}

# Configure monitoring for workshop
configure_monitoring() {
    log_debug "Checking monitoring configuration..."
    
    # Check if monitoring is available
    if oc get namespace openshift-monitoring >/dev/null 2>&1; then
        log_debug "Monitoring namespace exists"
        
        # Check if user workload monitoring is enabled
        if oc get configmap cluster-monitoring-config -n openshift-monitoring >/dev/null 2>&1; then
            local user_workload_enabled
            user_workload_enabled=$(oc get configmap cluster-monitoring-config -n openshift-monitoring -o jsonpath='{.data.config\.yaml}' | grep -q "enableUserWorkload: true" && echo "true" || echo "false")
            
            if [[ "$user_workload_enabled" == "false" ]]; then
                log_info "User workload monitoring is disabled, some workshop features may be limited"
            fi
        fi
    else
        log_warn "Monitoring namespace not found"
    fi
}

#######################################
# Validation and Health Checks
#######################################

# Validate Dev Spaces installation
validate_devspaces_installation() {
    log_step "Validating Dev Spaces installation..."
    
    # Check operator
    if ! oc get csv -n "$DEVSPACES_OPERATOR_NAMESPACE" | grep -q "devspaces.*Succeeded"; then
        log_error "Dev Spaces operator not properly installed"
        return 1
    fi
    
    # Check CheCluster
    local che_phase
    che_phase=$(oc get checluster "$CHECLUSTER_NAME" -n "$DEVSPACES_NAMESPACE" -o jsonpath='{.status.chePhase}' 2>/dev/null || echo "NotFound")
    
    if [[ "$che_phase" != "Active" ]]; then
        log_error "CheCluster is not active (phase: $che_phase)"
        return 1
    fi
    
    # Check Dev Spaces URL accessibility
    local devspaces_url
    devspaces_url=$(get_devspaces_url)
    
    if [[ -n "$devspaces_url" ]]; then
        log_info "Dev Spaces URL: $devspaces_url"
        
        if command_exists curl; then
            if curl -s -k -I "$devspaces_url" | grep -E 'HTTP/[0-9.]+ (200|302)' >/dev/null; then
                log_success "Dev Spaces is accessible"
            else
                log_warn "Dev Spaces URL may not be accessible"
            fi
        fi
    else
        log_error "Could not determine Dev Spaces URL"
        return 1
    fi
    
    log_success "Dev Spaces installation validated"
    return 0
}

# Get Dev Spaces URL
get_devspaces_url() {
    local devspaces_url=""
    
    # Try to get URL from route
    if oc get route devspaces -n "$DEVSPACES_NAMESPACE" >/dev/null 2>&1; then
        devspaces_url="https://$(oc get route devspaces -n "$DEVSPACES_NAMESPACE" -o jsonpath='{.spec.host}')"
    # Try to get URL from CheCluster status
    elif oc get checluster "$CHECLUSTER_NAME" -n "$DEVSPACES_NAMESPACE" >/dev/null 2>&1; then
        devspaces_url=$(oc get checluster "$CHECLUSTER_NAME" -n "$DEVSPACES_NAMESPACE" -o jsonpath='{.status.cheURL}' 2>/dev/null || echo "")
    fi
    
    echo "$devspaces_url"
}

#######################################
# Display Information
#######################################

# Display cluster setup information
display_cluster_setup_info() {
    log_step "Cluster setup information..."
    
    local devspaces_url
    devspaces_url=$(get_devspaces_url)
    
    local cluster_domain
    cluster_domain=$(get_cluster_domain)
    
    echo ""
    echo "=================================="
    echo "🚀 OpenShift Dev Spaces Setup Complete"
    echo "=================================="
    echo ""
    echo "📊 Cluster Information:"
    echo "  🌐 Cluster Domain: $cluster_domain"
    echo "  🚀 Dev Spaces URL: ${devspaces_url:-'Not available'}"
    echo "  👥 Multi-user support: Enabled"
    echo "  📝 User workspace template: <username>-devspaces"
    echo "  ⏱️  Workspace timeout: 30 minutes idle"
    echo "  📊 Max workspaces per user: 5"
    echo "  🏃 Max running workspaces per user: 3"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Create workshop users:"
    echo "   ./scripts/deploy-workshop.sh --workshop --count 20"
    echo "2. Or use existing users:"
    echo "   ./scripts/deploy-workshop.sh --workshop --use-existing"
    echo "3. Test the environment:"
    echo "   ./scripts/deploy-workshop.sh --test --workshop"
    echo ""
    echo "🔗 Workshop Repository:"
    echo "   https://github.com/tosin2013/dddhexagonalworkshop.git"
    echo "=================================="
}

#######################################
# Main Cluster Setup Function
#######################################

# Complete cluster setup for workshop
setup_cluster_for_workshop() {
    log_step "Setting up OpenShift cluster for DDD Workshop..."
    print_script_header "Cluster Setup" "Installing and configuring OpenShift Dev Spaces"
    
    # Validate prerequisites
    check_openshift_login || return 1
    check_cluster_admin || return 1
    
    # Install Dev Spaces operator
    install_devspaces_operator || return 1
    
    # Create CheCluster
    create_checluster || return 1
    
    # Configure cluster
    configure_cluster_for_workshop || return 1
    
    # Validate installation
    validate_devspaces_installation || return 1
    
    # Display information
    display_cluster_setup_info
    
    log_success "Cluster setup completed successfully!"
    return 0
}

# Export functions for use in other scripts
export -f install_devspaces_operator create_checluster configure_cluster_for_workshop
export -f validate_devspaces_installation get_devspaces_url display_cluster_setup_info
export -f setup_cluster_for_workshop

log_debug "Cluster setup library loaded"
