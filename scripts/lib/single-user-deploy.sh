#!/bin/bash
# Single-User Deployment Library for DDD Hexagonal Workshop
# Handles deployment for individual developers in their own environment
# Consolidates functionality from deploy-to-openshift.sh

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common-utils.sh
source "$SCRIPT_DIR/common-utils.sh"

# Configuration
readonly HELM_CHART_DIR="$PROJECT_ROOT/helm/ddd-workshop"
readonly DEFAULT_RELEASE_NAME="ddd-workshop"
readonly DEFAULT_ENVIRONMENT="dev"

#######################################
# Helm Deployment Functions
#######################################

# Deploy using Helm chart
deploy_helm_chart() {
    local release_name="$1"
    local namespace="$2"
    local environment="${3:-$DEFAULT_ENVIRONMENT}"
    
    log_step "Deploying Helm chart..."
    log_confidence "88" "Helm-based deployment process"
    
    # Validate Helm chart directory
    validate_directory "$HELM_CHART_DIR" "Helm chart directory"
    
    # Check if Helm is available
    if ! command_exists helm; then
        log_error "Helm is not installed"
        log_info "Please install Helm: https://helm.sh/docs/intro/install/"
        return 1
    fi
    
    # Prepare Helm arguments
    local helm_args=(
        "--namespace" "$namespace"
        "--create-namespace"
        "--set" "global.namespace=$namespace"
        "--set" "global.environment=$environment"
        "--timeout" "10m"
        "--wait"
    )
    
    # Add values file if it exists
    local values_file="$HELM_CHART_DIR/values-${environment}.yaml"
    if [[ -f "$values_file" ]]; then
        helm_args+=("--values" "$values_file")
        log_debug "Using values file: $values_file"
    fi
    
    # Check if release exists
    if helm list -n "$namespace" | grep -q "$release_name"; then
        log_info "Upgrading existing Helm release: $release_name"
        helm upgrade "$release_name" "$HELM_CHART_DIR" "${helm_args[@]}"
    else
        log_info "Installing new Helm release: $release_name"
        helm install "$release_name" "$HELM_CHART_DIR" "${helm_args[@]}"
    fi
    
    log_success "Helm deployment completed successfully"
}

# Verify Helm deployment
verify_helm_deployment() {
    local namespace="$1"
    local timeout="${2:-300}"
    
    log_step "Verifying Helm deployment..."
    
    # Wait for deployments to be ready
    log_info "Waiting for deployments to be ready (timeout: ${timeout}s)..."
    
    local deployments=("postgresql" "kafka")
    for deployment in "${deployments[@]}"; do
        local full_name="ddd-workshop-$deployment"
        
        if oc get deployment "$full_name" -n "$namespace" >/dev/null 2>&1; then
            log_info "Waiting for deployment: $full_name"
            if wait_for_deployment "$full_name" "$namespace" "$timeout"; then
                log_success "Deployment $full_name is ready"
            else
                log_error "Deployment $full_name failed to become ready"
                return 1
            fi
        else
            log_warn "Deployment $full_name not found (might be disabled)"
        fi
    done
    
    log_success "Helm deployment verification completed"
}

#######################################
# Single-User Environment Setup
#######################################

# Setup single-user namespace
setup_single_user_namespace() {
    local namespace="$1"
    local current_user
    current_user=$(oc whoami)
    
    log_step "Setting up single-user namespace: $namespace"
    
    # Create namespace with appropriate labels
    create_namespace_with_labels "$namespace" \
        "app.kubernetes.io/name=ddd-workshop" \
        "app.kubernetes.io/component=single-user" \
        "workshop.user=$current_user" \
        "workshop.mode=single-user"
    
    # Create resource quota for single user (more generous than multi-user)
    create_single_user_resource_quota "$namespace"
    
    # Ensure user has admin access to their namespace
    oc create rolebinding "${current_user}-admin" \
        --clusterrole=admin \
        --user="$current_user" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | oc apply -f -
    
    log_success "Single-user namespace setup completed: $namespace"
}

# Create resource quota for single-user deployment
create_single_user_resource_quota() {
    local namespace="$1"
    
    log_debug "Creating resource quota for single-user namespace: $namespace"
    
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ddd-workshop-single-user-quota
  namespace: $namespace
  labels:
    app.kubernetes.io/name: ddd-workshop
    app.kubernetes.io/component: resources
    workshop.mode: single-user
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.memory: "16Gi"
    persistentvolumeclaims: "10"
    pods: "20"
    services: "10"
    configmaps: "20"
    secrets: "20"
    routes.route.openshift.io: "5"
EOF
    
    log_debug "Resource quota created for single-user namespace: $namespace"
}

#######################################
# Development Environment Configuration
#######################################

# Configure development environment
configure_dev_environment() {
    local namespace="$1"
    local environment="${2:-$DEFAULT_ENVIRONMENT}"
    
    log_step "Configuring development environment..."
    
    # Create development-specific ConfigMap
    create_dev_configmap "$namespace" "$environment"
    
    # Setup development secrets if needed
    setup_dev_secrets "$namespace"
    
    log_success "Development environment configured"
}

# Create development ConfigMap
create_dev_configmap() {
    local namespace="$1"
    local environment="$2"
    
    log_debug "Creating development ConfigMap..."
    
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: ddd-workshop-dev-config
  namespace: $namespace
  labels:
    app.kubernetes.io/name: ddd-workshop
    app.kubernetes.io/component: config
    workshop.environment: $environment
data:
  environment: "$environment"
  debug.enabled: "true"
  logging.level: "DEBUG"
  quarkus.http.host: "0.0.0.0"
  quarkus.datasource.jdbc.url: "jdbc:postgresql://ddd-workshop-postgresql:5432/quarkus"
  kafka.bootstrap.servers: "ddd-workshop-kafka:9092"
EOF
    
    log_debug "Development ConfigMap created"
}

# Setup development secrets
setup_dev_secrets() {
    local namespace="$1"
    
    log_debug "Setting up development secrets..."
    
    # Create database credentials secret
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: ddd-workshop-db-credentials
  namespace: $namespace
  labels:
    app.kubernetes.io/name: ddd-workshop
    app.kubernetes.io/component: database
type: Opaque
stringData:
  username: "quarkus"
  password: "quarkus"
  database: "quarkus"
EOF
    
    log_debug "Development secrets created"
}

#######################################
# Single-User Deployment Orchestration
#######################################

# Complete single-user deployment
deploy_single_user_environment() {
    local namespace="$1"
    local environment="${2:-$DEFAULT_ENVIRONMENT}"
    local release_name="${3:-$DEFAULT_RELEASE_NAME}"
    
    log_step "Deploying single-user workshop environment..."
    print_script_header "Single-User Deployment" "Deploying workshop for individual developer"
    
    local current_user
    current_user=$(oc whoami)
    
    log_info "Configuration:"
    log_info "  - User: $current_user"
    log_info "  - Namespace: $namespace"
    log_info "  - Environment: $environment"
    log_info "  - Release Name: $release_name"
    log_info "  - Helm Chart: $HELM_CHART_DIR"
    echo ""
    
    # Validate prerequisites
    check_openshift_login || return 1
    
    # Setup namespace
    setup_single_user_namespace "$namespace" || return 1
    
    # Configure development environment
    configure_dev_environment "$namespace" "$environment" || return 1
    
    # Deploy using Helm
    deploy_helm_chart "$release_name" "$namespace" "$environment" || return 1
    
    # Verify deployment
    verify_helm_deployment "$namespace" || return 1
    
    # Display access information
    display_single_user_access_info "$namespace" "$current_user"
    
    log_success "Single-user deployment completed successfully!"
}

# Display single-user access information
display_single_user_access_info() {
    local namespace="$1"
    local username="$2"
    
    log_step "Single-user access information..."
    
    local cluster_domain
    cluster_domain=$(get_cluster_domain)
    
    # Get application routes
    local app_routes=()
    while IFS= read -r route; do
        [[ -n "$route" ]] && app_routes+=("$route")
    done < <(oc get routes -n "$namespace" -o jsonpath='{.items[*].spec.host}' 2>/dev/null | tr ' ' '\n' || true)
    
    echo ""
    echo "=== Single-User Workshop Access ==="
    echo ""
    echo "👤 User: $username"
    echo "📁 Namespace: $namespace"
    echo "🌐 Cluster Domain: $cluster_domain"
    echo ""
    
    if [[ ${#app_routes[@]} -gt 0 ]]; then
        echo "🔗 Application Routes:"
        for route in "${app_routes[@]}"; do
            echo "   https://$route"
        done
        echo ""
    fi
    
    echo "📊 Resources:"
    echo "   Deployments: $(oc get deployments -n "$namespace" --no-headers 2>/dev/null | wc -l || echo "0")"
    echo "   Services: $(oc get services -n "$namespace" --no-headers 2>/dev/null | wc -l || echo "0")"
    echo "   ConfigMaps: $(oc get configmaps -n "$namespace" --no-headers 2>/dev/null | wc -l || echo "0")"
    echo ""
    
    echo "📋 Next Steps:"
    echo "1. Check deployment status:"
    echo "   oc get pods -n $namespace"
    echo "2. View application logs:"
    echo "   oc logs -f deployment/ddd-workshop-quarkus -n $namespace"
    echo "3. Access application (if route exists):"
    if [[ ${#app_routes[@]} -gt 0 ]]; then
        echo "   https://${app_routes[0]}"
    else
        echo "   oc port-forward svc/ddd-workshop-quarkus 8080:8080 -n $namespace"
    fi
    echo "4. Run tests:"
    echo "   ./scripts/deploy-workshop.sh --test --single-user"
    echo ""
    echo "🔗 Workshop Repository:"
    echo "   https://github.com/tosin2013/dddhexagonalworkshop.git"
    echo "=================================="
}

#######################################
# Cleanup Functions
#######################################

# Cleanup single-user environment
cleanup_single_user_environment() {
    local namespace="$1"
    local release_name="${2:-$DEFAULT_RELEASE_NAME}"
    
    log_step "Cleaning up single-user environment..."
    
    if ! confirm_action "Remove namespace $namespace and all resources?"; then
        log_info "Cleanup cancelled"
        return 0
    fi
    
    # Remove Helm release if it exists
    if command_exists helm && helm list -n "$namespace" | grep -q "$release_name"; then
        log_info "Removing Helm release: $release_name"
        helm uninstall "$release_name" -n "$namespace"
    fi
    
    # Remove namespace
    if namespace_exists "$namespace"; then
        log_info "Removing namespace: $namespace"
        oc delete namespace "$namespace" --ignore-not-found=true
    fi
    
    log_success "Single-user environment cleanup completed"
}

# Export functions for use in other scripts
export -f deploy_helm_chart verify_helm_deployment
export -f setup_single_user_namespace create_single_user_resource_quota
export -f configure_dev_environment create_dev_configmap setup_dev_secrets
export -f deploy_single_user_environment display_single_user_access_info
export -f cleanup_single_user_environment

# log_debug "Single-user deployment library loaded"
