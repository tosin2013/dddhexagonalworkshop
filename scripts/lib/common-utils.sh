#!/bin/bash
# Common Utilities for DDD Hexagonal Workshop Scripts
# Shared functions for logging, validation, and OpenShift operations
# Following methodological pragmatism principles for systematic verification

# Prevent multiple loading
if [[ -n "${COMMON_UTILS_LOADED:-}" ]]; then
    return 0
fi

set -euo pipefail

# Global configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
UTILS_VERSION="1.0.0"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Logging levels
readonly LOG_LEVEL_ERROR=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_INFO=3
readonly LOG_LEVEL_DEBUG=4

# Default log level (can be overridden by LOG_LEVEL environment variable)
LOG_LEVEL=${LOG_LEVEL:-$LOG_LEVEL_INFO}

#######################################
# Logging Functions
#######################################

log_error() {
    [[ $LOG_LEVEL -ge $LOG_LEVEL_ERROR ]] && echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    [[ $LOG_LEVEL -ge $LOG_LEVEL_WARN ]] && echo -e "${YELLOW}[WARN]${NC} $1" >&2
}

log_info() {
    [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]] && echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]] && echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_debug() {
    [[ $LOG_LEVEL -ge $LOG_LEVEL_DEBUG ]] && echo -e "${PURPLE}[DEBUG]${NC} $1"
}

log_step() {
    [[ $LOG_LEVEL -ge $LOG_LEVEL_INFO ]] && echo -e "${CYAN}==>${NC} $1"
}

# Confidence-based logging for methodological pragmatism
log_confidence() {
    local confidence="$1"
    local message="$2"
    local color="${GREEN}"

    # Use bash arithmetic instead of bc
    if (( confidence < 70 )); then
        color="${RED}"
    elif (( confidence < 85 )); then
        color="${YELLOW}"
    fi

    echo -e "${color}[CONFIDENCE: ${confidence}%]${NC} $message"
}

#######################################
# Validation Functions
#######################################

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate required commands are available
validate_required_commands() {
    local commands=("$@")
    local missing_commands=()
    
    for cmd in "${commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [[ ${#missing_commands[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        log_info "Please install the missing commands and try again"
        return 1
    fi
    
    log_debug "All required commands available: ${commands[*]}"
    return 0
}

# Validate file exists and is readable
validate_file() {
    local file="$1"
    local description="${2:-file}"
    
    if [[ ! -f "$file" ]]; then
        log_error "$description not found: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        log_error "$description not readable: $file"
        return 1
    fi
    
    log_debug "Validated $description: $file"
    return 0
}

# Validate directory exists and is accessible
validate_directory() {
    local dir="$1"
    local description="${2:-directory}"
    
    if [[ ! -d "$dir" ]]; then
        log_error "$description not found: $dir"
        return 1
    fi
    
    if [[ ! -r "$dir" ]]; then
        log_error "$description not accessible: $dir"
        return 1
    fi
    
    log_debug "Validated $description: $dir"
    return 0
}

# Validate numeric value within range
validate_numeric_range() {
    local value="$1"
    local min="$2"
    local max="$3"
    local description="${4:-value}"
    
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        log_error "$description must be a number: $value"
        return 1
    fi
    
    if [[ $value -lt $min ]] || [[ $value -gt $max ]]; then
        log_error "$description must be between $min and $max: $value"
        return 1
    fi
    
    log_debug "Validated $description: $value"
    return 0
}

#######################################
# OpenShift Utilities
#######################################

# Check if logged into OpenShift
check_openshift_login() {
    if ! command_exists oc; then
        log_error "OpenShift CLI (oc) not found"
        log_info "Please install the OpenShift CLI: https://docs.openshift.com/container-platform/latest/cli_reference/openshift_cli/getting-started-cli.html"
        return 1
    fi
    
    if ! oc whoami &>/dev/null; then
        log_error "Not logged into OpenShift cluster"
        log_info "Please run 'oc login' to authenticate with your OpenShift cluster"
        return 1
    fi
    
    local current_user
    current_user=$(oc whoami)
    local current_server
    current_server=$(oc whoami --show-server)
    
    log_info "OpenShift login verified"
    log_debug "User: $current_user"
    log_debug "Server: $current_server"
    return 0
}

# Check cluster admin permissions
check_cluster_admin() {
    if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
        log_error "Cluster admin permissions required"
        log_info "Current user: $(oc whoami)"
        log_info "Please ensure you have cluster-admin role or equivalent permissions"
        return 1
    fi
    
    log_success "Cluster admin permissions verified"
    return 0
}

# Get cluster domain
get_cluster_domain() {
    local domain
    domain=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' 2>/dev/null)
    
    if [[ -z "$domain" ]]; then
        log_error "Unable to determine cluster domain"
        return 1
    fi
    
    echo "$domain"
}

# Check if namespace exists
namespace_exists() {
    local namespace="$1"
    oc get namespace "$namespace" &>/dev/null
}

# Create namespace with labels
create_namespace_with_labels() {
    local namespace="$1"
    shift
    local labels=("$@")
    
    if namespace_exists "$namespace"; then
        log_info "Namespace $namespace already exists"
        return 0
    fi
    
    log_info "Creating namespace: $namespace"
    oc create namespace "$namespace"
    
    # Apply labels
    for label in "${labels[@]}"; do
        log_debug "Applying label: $label"
        oc label namespace "$namespace" "$label" --overwrite
    done
    
    log_success "Namespace $namespace created with labels"
}

# Wait for deployment to be ready
wait_for_deployment() {
    local deployment="$1"
    local namespace="$2"
    local timeout="${3:-300}"
    
    log_info "Waiting for deployment $deployment in namespace $namespace (timeout: ${timeout}s)"
    
    if oc rollout status deployment/"$deployment" -n "$namespace" --timeout="${timeout}s"; then
        log_success "Deployment $deployment is ready"
        return 0
    else
        log_error "Deployment $deployment failed to become ready within ${timeout}s"
        return 1
    fi
}

#######################################
# Resource Management
#######################################

# Check cluster resource availability
check_cluster_resources() {
    local required_memory_gi="${1:-4}"
    local required_cpu="${2:-2}"
    
    log_step "Checking cluster resource availability"
    
    # Get node resources (simplified check)
    local total_memory_ki
    total_memory_ki=$(oc get nodes -o jsonpath='{.items[*].status.allocatable.memory}' | tr ' ' '\n' | sed 's/Ki$//' | awk '{sum += $1} END {print sum}')
    local total_memory_gi=$((total_memory_ki / 1024 / 1024))
    
    local total_cpu_m
    total_cpu_m=$(oc get nodes -o jsonpath='{.items[*].status.allocatable.cpu}' | tr ' ' '\n' | sed 's/m$//' | awk '{sum += $1} END {print sum}')
    local total_cpu=$((total_cpu_m / 1000))
    
    log_info "Cluster resources - Memory: ${total_memory_gi}Gi, CPU: ${total_cpu} cores"
    log_info "Required resources - Memory: ${required_memory_gi}Gi, CPU: ${required_cpu} cores"
    
    if [[ $total_memory_gi -lt $required_memory_gi ]]; then
        log_warn "Insufficient memory: ${total_memory_gi}Gi available, ${required_memory_gi}Gi required"
        return 1
    fi
    
    if [[ $total_cpu -lt $required_cpu ]]; then
        log_warn "Insufficient CPU: ${total_cpu} cores available, ${required_cpu} cores required"
        return 1
    fi
    
    log_success "Sufficient cluster resources available"
    return 0
}

#######################################
# Utility Functions
#######################################

# Confirm action with user
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [[ "${FORCE:-false}" == "true" ]]; then
        log_debug "Skipping confirmation (FORCE=true): $message"
        return 0
    fi
    
    local prompt="$message [y/N]: "
    if [[ "$default" == "y" ]]; then
        prompt="$message [Y/n]: "
    fi
    
    read -p "$prompt" -r response
    response=${response:-$default}
    
    case "$response" in
        [yY]|[yY][eE][sS])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Generate random string
generate_random_string() {
    local length="${1:-8}"
    tr -dc 'a-zA-Z0-9' < /dev/urandom | head -c "$length"
}

# Print script header
print_script_header() {
    local script_name="$1"
    local description="$2"
    local version="${3:-$UTILS_VERSION}"
    
    echo "========================================"
    echo "$script_name"
    echo "$description"
    echo "Version: $version"
    echo "Repository: https://github.com/tosin2013/dddhexagonalworkshop.git"
    echo "Author: Tosin Akinosho <takinosh@redhat.com>"
    echo "========================================"
    echo ""
}

# Export functions for use in other scripts
export -f log_error log_warn log_info log_success log_debug log_step log_confidence
export -f command_exists validate_required_commands validate_file validate_directory validate_numeric_range
export -f check_openshift_login check_cluster_admin get_cluster_domain namespace_exists create_namespace_with_labels wait_for_deployment
export -f check_cluster_resources confirm_action generate_random_string

# Mark as loaded to prevent circular dependencies
COMMON_UTILS_LOADED=true
# Temporarily disable debug logging to avoid hanging
# log_debug "Common utilities loaded (version: $UTILS_VERSION)"
