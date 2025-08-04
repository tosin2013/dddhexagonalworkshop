#!/bin/bash
# OpenShift Deployment Script for DDD Hexagonal Workshop
# This script deploys the workshop infrastructure using Helm charts

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
HELM_CHART_DIR="$PROJECT_ROOT/helm/ddd-workshop"

# Default values
DEFAULT_NAMESPACE="ddd-workshop"
DEFAULT_ENVIRONMENT="dev"
DEFAULT_RELEASE_NAME="ddd-workshop"

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

# Function to check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check if oc is installed and logged in
    if ! command -v oc >/dev/null 2>&1; then
        log_error "OpenShift CLI (oc) is not installed"
        exit 1
    fi
    
    if ! oc whoami >/dev/null 2>&1; then
        log_error "Not logged in to OpenShift cluster"
        log_info "Please login using: oc login --token=<token> --server=<server>"
        exit 1
    fi
    
    # Check if helm is installed
    if ! command -v helm >/dev/null 2>&1; then
        log_error "Helm is not installed"
        log_info "Please install Helm: https://helm.sh/docs/intro/install/"
        exit 1
    fi
    
    # Check if helm chart exists
    if [ ! -d "$HELM_CHART_DIR" ]; then
        log_error "Helm chart directory not found: $HELM_CHART_DIR"
        exit 1
    fi
    
    log_info "✅ Prerequisites check passed"
    log_info "  - OpenShift CLI: $(oc version --client -o json | jq -r '.clientVersion.gitVersion')"
    log_info "  - Helm: $(helm version --short)"
    log_info "  - Current user: $(oc whoami)"
    log_info "  - Current project: $(oc project -q 2>/dev/null || echo 'none')"
}

# Function to create or switch to namespace
setup_namespace() {
    local namespace="$1"
    
    log_step "Setting up namespace: $namespace"
    
    if oc get namespace "$namespace" >/dev/null 2>&1; then
        log_info "Namespace $namespace already exists"
    else
        log_info "Creating namespace: $namespace"
        oc create namespace "$namespace"
        
        # Add labels for OpenShift Dev Spaces integration
        oc label namespace "$namespace" \
            app.kubernetes.io/name=ddd-workshop \
            app.kubernetes.io/part-of=ddd-workshop \
            workshop.redhat.com/type=ddd-hexagonal
    fi
    
    # Switch to the namespace
    oc project "$namespace"
    log_info "✅ Using namespace: $namespace"
}

# Function to install or upgrade Helm release
deploy_helm_chart() {
    local release_name="$1"
    local namespace="$2"
    local environment="$3"
    local values_file="$HELM_CHART_DIR/values-${environment}.yaml"
    
    log_step "Deploying Helm chart..."
    
    # Check if values file exists
    if [ ! -f "$values_file" ]; then
        log_warn "Environment-specific values file not found: $values_file"
        log_info "Using default values.yaml"
        values_file="$HELM_CHART_DIR/values.yaml"
    fi
    
    # Prepare Helm command
    local helm_cmd="helm"
    local helm_args=(
        "--namespace" "$namespace"
        "--values" "$values_file"
        "--set" "global.namespace=$namespace"
        "--set" "environment=$environment"
        "--timeout" "10m"
        "--wait"
    )
    
    # Check if release exists
    if helm list -n "$namespace" | grep -q "$release_name"; then
        log_info "Upgrading existing Helm release: $release_name"
        $helm_cmd upgrade "$release_name" "$HELM_CHART_DIR" "${helm_args[@]}"
    else
        log_info "Installing new Helm release: $release_name"
        $helm_cmd install "$release_name" "$HELM_CHART_DIR" "${helm_args[@]}"
    fi
    
    log_info "✅ Helm deployment completed successfully"
}

# Function to verify deployment
verify_deployment() {
    local namespace="$1"
    local timeout=300  # 5 minutes
    
    log_step "Verifying deployment..."
    
    # Wait for deployments to be ready
    log_info "Waiting for deployments to be ready (timeout: ${timeout}s)..."
    
    local deployments=("postgresql" "kafka" "quarkus")
    for deployment in "${deployments[@]}"; do
        local full_name="ddd-workshop-$deployment"
        if oc get deployment "$full_name" -n "$namespace" >/dev/null 2>&1; then
            log_info "Waiting for deployment: $full_name"
            if oc rollout status deployment/"$full_name" -n "$namespace" --timeout="${timeout}s"; then
                log_info "✅ Deployment $full_name is ready"
            else
                log_error "❌ Deployment $full_name failed to become ready"
                return 1
            fi
        else
            log_warn "⚠️  Deployment $full_name not found (might be disabled)"
        fi
    done
    
    # Check pod status
    log_info "Checking pod status..."
    oc get pods -n "$namespace" -l app.kubernetes.io/name=ddd-workshop
    
    # Check services
    log_info "Checking services..."
    oc get services -n "$namespace" -l app.kubernetes.io/name=ddd-workshop
    
    # Check routes
    log_info "Checking routes..."
    if oc get routes -n "$namespace" >/dev/null 2>&1; then
        oc get routes -n "$namespace" -l app.kubernetes.io/name=ddd-workshop
    fi
    
    log_info "✅ Deployment verification completed"
}

# Function to display access information
display_access_info() {
    local namespace="$1"
    
    log_step "Access Information"
    echo "=================================="
    
    # Get route information
    if oc get routes -n "$namespace" -l app.kubernetes.io/name=ddd-workshop >/dev/null 2>&1; then
        local route_url
        route_url=$(oc get route ddd-workshop-quarkus -n "$namespace" -o jsonpath='{.spec.host}' 2>/dev/null || echo "")
        if [ -n "$route_url" ]; then
            echo "🌐 Application URL: https://$route_url"
            echo "📊 Health Check: https://$route_url/q/health"
            echo "📖 Swagger UI: https://$route_url/q/swagger-ui"
            echo "🔍 Dev UI: https://$route_url/q/dev"
        fi
    fi
    
    # Get service information
    echo ""
    echo "🔧 Internal Services:"
    oc get services -n "$namespace" -l app.kubernetes.io/name=ddd-workshop --no-headers | while read -r line; do
        local service_name
        service_name=$(echo "$line" | awk '{print $1}')
        local service_port
        service_port=$(echo "$line" | awk '{print $5}' | cut -d'/' -f1)
        echo "  - $service_name: $service_name.$namespace.svc.cluster.local:$service_port"
    done
    
    echo ""
    echo "📝 Useful Commands:"
    echo "  - View pods: oc get pods -n $namespace"
    echo "  - View logs: oc logs -f deployment/ddd-workshop-quarkus -n $namespace"
    echo "  - Port forward: oc port-forward svc/ddd-workshop-quarkus 8080:8080 -n $namespace"
    echo "  - Delete deployment: helm uninstall ddd-workshop -n $namespace"
    echo "=================================="
}

# Function to run post-deployment tests
run_post_deployment_tests() {
    local namespace="$1"
    
    log_step "Running post-deployment tests..."
    
    # Test PostgreSQL connectivity
    log_info "Testing PostgreSQL connectivity..."
    if oc exec -n "$namespace" deployment/ddd-workshop-postgresql -- pg_isready -U attendee >/dev/null 2>&1; then
        log_info "✅ PostgreSQL is ready"
    else
        log_warn "⚠️  PostgreSQL connectivity test failed"
    fi
    
    # Test Kafka connectivity
    log_info "Testing Kafka connectivity..."
    if oc exec -n "$namespace" deployment/ddd-workshop-kafka -- kafka-broker-api-versions.sh --bootstrap-server localhost:9092 >/dev/null 2>&1; then
        log_info "✅ Kafka is ready"
    else
        log_warn "⚠️  Kafka connectivity test failed"
    fi
    
    # Test Quarkus health endpoints
    if oc get routes ddd-workshop-quarkus -n "$namespace" >/dev/null 2>&1; then
        local route_url
        route_url=$(oc get route ddd-workshop-quarkus -n "$namespace" -o jsonpath='{.spec.host}')
        if [ -n "$route_url" ]; then
            log_info "Testing Quarkus health endpoints..."
            if curl -s "https://$route_url/q/health" >/dev/null 2>&1; then
                log_info "✅ Quarkus application is healthy"
            else
                log_warn "⚠️  Quarkus health check failed"
            fi
        fi
    fi
    
    log_info "✅ Post-deployment tests completed"
}

# Function to handle cleanup
cleanup() {
    local namespace="$1"
    local release_name="$2"
    
    log_step "Cleaning up deployment..."
    
    if helm list -n "$namespace" | grep -q "$release_name"; then
        log_info "Uninstalling Helm release: $release_name"
        helm uninstall "$release_name" -n "$namespace"
    fi
    
    # Optionally delete namespace
    read -p "Do you want to delete the namespace '$namespace'? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Deleting namespace: $namespace"
        oc delete namespace "$namespace"
    fi
    
    log_info "✅ Cleanup completed"
}

# Main deployment function
main() {
    local namespace="${NAMESPACE:-$DEFAULT_NAMESPACE}"
    local environment="${ENVIRONMENT:-$DEFAULT_ENVIRONMENT}"
    local release_name="${RELEASE_NAME:-$DEFAULT_RELEASE_NAME}"
    
    log_info "Starting OpenShift deployment for DDD Hexagonal Workshop"
    log_info "Configuration:"
    log_info "  - Namespace: $namespace"
    log_info "  - Environment: $environment"
    log_info "  - Release Name: $release_name"
    log_info "  - Helm Chart: $HELM_CHART_DIR"
    echo ""
    
    check_prerequisites
    echo ""
    
    setup_namespace "$namespace"
    echo ""
    
    deploy_helm_chart "$release_name" "$namespace" "$environment"
    echo ""
    
    verify_deployment "$namespace"
    echo ""
    
    run_post_deployment_tests "$namespace"
    echo ""
    
    display_access_info "$namespace"
    
    log_info "🎉 OpenShift deployment completed successfully!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "OpenShift Deployment Script for DDD Hexagonal Workshop"
        echo ""
        echo "Usage: $0 [OPTIONS] [COMMAND]"
        echo ""
        echo "Commands:"
        echo "  deploy                 Deploy the workshop (default)"
        echo "  cleanup                Clean up the deployment"
        echo "  verify                 Verify existing deployment"
        echo "  test                   Run post-deployment tests"
        echo ""
        echo "Options:"
        echo "  --namespace NAME       Target namespace (default: $DEFAULT_NAMESPACE)"
        echo "  --environment ENV      Environment (dev/staging/prod, default: $DEFAULT_ENVIRONMENT)"
        echo "  --release-name NAME    Helm release name (default: $DEFAULT_RELEASE_NAME)"
        echo "  --help, -h             Show this help message"
        echo ""
        echo "Environment Variables:"
        echo "  NAMESPACE              Target namespace"
        echo "  ENVIRONMENT            Environment (dev/staging/prod)"
        echo "  RELEASE_NAME           Helm release name"
        echo ""
        echo "Examples:"
        echo "  $0 --namespace my-workshop --environment staging"
        echo "  $0 cleanup --namespace my-workshop"
        echo "  ENVIRONMENT=prod $0 --namespace ddd-workshop-prod"
        exit 0
        ;;
    --namespace)
        NAMESPACE="$2"
        shift 2
        ;;
    --environment)
        ENVIRONMENT="$2"
        shift 2
        ;;
    --release-name)
        RELEASE_NAME="$2"
        shift 2
        ;;
    cleanup)
        cleanup "${NAMESPACE:-$DEFAULT_NAMESPACE}" "${RELEASE_NAME:-$DEFAULT_RELEASE_NAME}"
        exit 0
        ;;
    verify)
        verify_deployment "${NAMESPACE:-$DEFAULT_NAMESPACE}"
        exit 0
        ;;
    test)
        run_post_deployment_tests "${NAMESPACE:-$DEFAULT_NAMESPACE}"
        exit 0
        ;;
    deploy|"")
        # Default action - deploy
        ;;
    *)
        log_error "Unknown command: $1"
        log_info "Use --help for usage information"
        exit 1
        ;;
esac

# Run main function
main
