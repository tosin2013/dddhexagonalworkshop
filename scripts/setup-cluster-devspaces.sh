#!/bin/bash
# Cluster Setup Script for OpenShift Dev Spaces
# This script sets up the cluster-level components for the DDD workshop

set -e

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

# Check if user has cluster-admin privileges
check_cluster_admin() {
    log_step "Checking cluster-admin privileges..."
    
    if ! oc auth can-i create clusterroles >/dev/null 2>&1; then
        log_error "This script requires cluster-admin privileges"
        log_error "Please login as cluster-admin or ask your administrator to run this script"
        exit 1
    fi
    
    log_info "✅ Cluster-admin privileges confirmed"
}

# Install OpenShift Dev Spaces operator
install_devspaces_operator() {
    log_step "Installing OpenShift Dev Spaces operator..."
    
    # Check if already installed
    if oc get csv -n openshift-devspaces | grep -q devspaces; then
        log_info "OpenShift Dev Spaces operator already installed"
        return 0
    fi
    
    # Apply operator subscription
    oc apply -f cluster-setup/01-devspaces-operator.yaml
    
    log_info "Waiting for operator to be installed..."
    
    # Wait for the operator to be ready
    local timeout=300
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if oc get csv -n openshift-devspaces | grep -q "devspaces.*Succeeded"; then
            log_info "✅ OpenShift Dev Spaces operator installed successfully"
            return 0
        fi
        
        echo -n "."
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    log_error "❌ Timeout waiting for operator installation"
    return 1
}

# Create CheCluster
create_checluster() {
    log_step "Creating CheCluster for multi-user support..."
    
    # Check if CheCluster already exists
    if oc get checluster devspaces -n openshift-devspaces >/dev/null 2>&1; then
        log_info "CheCluster already exists"
        return 0
    fi
    
    # Apply CheCluster configuration
    oc apply -f cluster-setup/02-checluster.yaml
    
    log_info "Waiting for CheCluster to be ready..."
    
    # Wait for CheCluster to be available
    local timeout=600
    local elapsed=0
    
    while [ $elapsed -lt $timeout ]; do
        if oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.chePhase}' | grep -q "Active"; then
            log_info "✅ CheCluster is active and ready"
            return 0
        fi
        
        echo -n "."
        sleep 15
        elapsed=$((elapsed + 15))
    done
    
    log_error "❌ Timeout waiting for CheCluster to be ready"
    return 1
}

# Display access information
display_access_info() {
    log_step "OpenShift Dev Spaces Access Information"
    
    local devspaces_url
    devspaces_url=$(oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}' 2>/dev/null || echo "")
    
    if [ -n "$devspaces_url" ]; then
        echo "=================================="
        echo "🚀 OpenShift Dev Spaces URL: $devspaces_url"
        echo "👥 Multi-user support: Enabled"
        echo "📝 User workspace template: <username>-devspaces"
        echo "⏱️  Workspace timeout: 30 minutes idle"
        echo "📊 Max workspaces per user: 5"
        echo "🏃 Max running workspaces per user: 3"
        echo "=================================="
        echo ""
        echo "📋 Next Steps:"
        echo "1. Users can access Dev Spaces at: $devspaces_url"
        echo "2. Deploy per-user infrastructure using:"
        echo "   ./scripts/deploy-user-infrastructure.sh <username>"
        echo "3. Users create workspaces with repository:"
        echo "   https://github.com/jeremyrdavis/dddhexagonalworkshop.git"
    else
        log_warn "Could not retrieve Dev Spaces URL"
    fi
}

# Main function
main() {
    log_info "🚀 Setting up OpenShift Dev Spaces for DDD Workshop"
    log_info "This will install cluster-level components for multi-user support"
    echo ""
    
    check_cluster_admin
    echo ""
    
    install_devspaces_operator
    echo ""
    
    create_checluster
    echo ""
    
    display_access_info
    
    log_info "✅ Cluster setup completed successfully!"
    log_info "Users can now create workspaces and administrators can deploy per-user infrastructure"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "OpenShift Dev Spaces Cluster Setup Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "This script installs cluster-level components:"
        echo "- OpenShift Dev Spaces operator"
        echo "- CheCluster with multi-user configuration"
        echo ""
        echo "Options:"
        echo "  --help, -h             Show this help message"
        echo "  --operator-only        Install only the operator"
        echo "  --checluster-only      Create only the CheCluster"
        echo ""
        echo "Requirements:"
        echo "- cluster-admin privileges"
        echo "- OpenShift 4.14+"
        exit 0
        ;;
    --operator-only)
        check_cluster_admin
        install_devspaces_operator
        exit 0
        ;;
    --checluster-only)
        check_cluster_admin
        create_checluster
        display_access_info
        exit 0
        ;;
esac

# Run main function
main
