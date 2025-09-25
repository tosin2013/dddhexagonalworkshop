#!/bin/bash
# User Management Library for DDD Hexagonal Workshop
# Handles HTPasswd user creation, RBAC setup, and user detection
# Consolidates functionality from create-workshop-users.sh and user detection logic

set -euo pipefail

# Source common utilities if not already loaded
if [[ -z "${COMMON_UTILS_LOADED:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=scripts/lib/common-utils.sh
    source "$SCRIPT_DIR/common-utils.sh"
fi

# Global variables for user management
declare -a DETECTED_HTPASSWD_USERS=()
declare -a DETECTED_USER_PATTERN_USERS=()

#######################################
# User Detection Functions
#######################################

# Detect existing HTPasswd users with pattern filtering
detect_existing_htpasswd_users() {
    local silent_mode="${1:-false}"
    local user_pattern="${2:-user[0-9]+}"
    
    if [[ "$silent_mode" != "true" ]]; then
        log_step "Detecting existing HTPasswd users..."
    fi
    
    local htpasswd_users=()
    local pattern_users=()
    
    # Check if HTPasswd secret exists
    if oc get secret htpasswd -n openshift-config >/dev/null 2>&1; then
        # Extract all HTPasswd users
        while IFS= read -r user; do
            [[ -n "$user" ]] && htpasswd_users+=("$user")
        done < <(oc get secret htpasswd -n openshift-config -o jsonpath='{.data.htpasswd}' 2>/dev/null | base64 -d | cut -d: -f1 || true)
        
        # Filter for pattern users (default: user1, user2, etc.)
        for user in "${htpasswd_users[@]}"; do
            if [[ "$user" =~ ^${user_pattern}$ ]]; then
                pattern_users+=("$user")
            fi
        done
        
        if [[ "$silent_mode" != "true" ]]; then
            log_info "Found ${#htpasswd_users[@]} total HTPasswd users"
            log_info "Found ${#pattern_users[@]} pattern users (${user_pattern}): ${pattern_users[*]}"
        fi
        
        # Check for existing user namespaces
        local existing_namespaces=()
        for user in "${pattern_users[@]}"; do
            if namespace_exists "${user}-devspaces"; then
                existing_namespaces+=("${user}-devspaces")
            fi
        done
        
        if [[ "$silent_mode" != "true" && ${#existing_namespaces[@]} -gt 0 ]]; then
            log_info "Found ${#existing_namespaces[@]} existing user namespaces: ${existing_namespaces[*]}"
        fi
    else
        if [[ "$silent_mode" != "true" ]]; then
            log_info "No HTPasswd secret found"
        fi
    fi
    
    # Store results in global variables
    DETECTED_HTPASSWD_USERS=("${htpasswd_users[@]}")
    DETECTED_USER_PATTERN_USERS=("${pattern_users[@]}")
    
    return 0
}

# Get detected users (must call detect_existing_htpasswd_users first)
get_detected_pattern_users() {
    echo "${DETECTED_USER_PATTERN_USERS[@]}"
}

get_detected_all_users() {
    echo "${DETECTED_HTPASSWD_USERS[@]}"
}

#######################################
# User Creation Functions
#######################################

# Create HTPasswd users
create_htpasswd_users() {
    local user_prefix="$1"
    local num_users="$2"
    local password="$3"
    local temp_htpasswd="/tmp/workshop-htpasswd-$$"
    
    log_step "Creating HTPasswd users..."
    log_info "User prefix: $user_prefix"
    log_info "Number of users: $num_users"
    log_confidence "85" "HTPasswd user creation process"
    
    # Validate inputs
    validate_numeric_range "$num_users" 1 100 "number of users"
    
    # Get existing htpasswd file or create empty one
    if oc get secret htpasswd -n openshift-config >/dev/null 2>&1; then
        log_info "Retrieving existing HTPasswd configuration"
        oc get secret htpasswd -n openshift-config -o jsonpath='{.data.htpasswd}' | base64 -d > "$temp_htpasswd"
    else
        log_info "Creating new HTPasswd configuration"
        touch "$temp_htpasswd"
    fi
    
    # Install htpasswd tools if needed
    if ! command_exists htpasswd; then
        log_info "Installing htpasswd tools..."
        if command_exists yum; then
            sudo yum install -y httpd-tools >/dev/null 2>&1
        elif command_exists apt-get; then
            sudo apt-get install -y apache2-utils >/dev/null 2>&1
        else
            log_error "Cannot install htpasswd tools. Please install httpd-tools or apache2-utils manually."
            rm -f "$temp_htpasswd"
            return 1
        fi
    fi
    
    # Create users
    local created_users=()
    for i in $(seq 1 "$num_users"); do
        local username="${user_prefix}${i}"
        log_debug "Creating user: $username"
        
        # Add or update user in htpasswd file
        if htpasswd -bB "$temp_htpasswd" "$username" "$password" 2>/dev/null; then
            created_users+=("$username")
        else
            log_error "Failed to create user: $username"
            rm -f "$temp_htpasswd"
            return 1
        fi
    done
    
    # Update the htpasswd secret
    log_info "Updating HTPasswd secret in OpenShift..."
    if oc create secret generic htpasswd --from-file=htpasswd="$temp_htpasswd" --dry-run=client -o yaml | oc replace -f - -n openshift-config; then
        log_success "HTPasswd secret updated successfully"
    else
        log_error "Failed to update HTPasswd secret"
        rm -f "$temp_htpasswd"
        return 1
    fi
    
    # Clean up temporary file
    rm -f "$temp_htpasswd"
    
    # Wait for authentication operator to sync
    log_info "Waiting for authentication operator to sync..."
    sleep 10
    
    log_success "Created ${#created_users[@]} users: ${created_users[*]}"
    return 0
}

#######################################
# Namespace and RBAC Functions
#######################################

# Create user namespace with proper labels and RBAC
create_user_namespace() {
    local username="$1"
    local namespace_suffix="${2:-devspaces}"
    local namespace="${username}-${namespace_suffix}"
    
    log_debug "Creating namespace for user: $username"
    
    # Create namespace with workshop labels
    create_namespace_with_labels "$namespace" \
        "app.kubernetes.io/name=ddd-workshop" \
        "app.kubernetes.io/component=user-environment" \
        "workshop.user=$username" \
        "workshop.redhat.com/user=$username" \
        "workshop.redhat.com/author=takinosh"
    
    # Create resource quota compatible with Dev Spaces
    create_user_resource_quota "$namespace"
    
    # Create RBAC for user
    create_user_rbac "$username" "$namespace"
    
    log_success "User namespace created: $namespace"
    return 0
}

# Create resource quota for user namespace
create_user_resource_quota() {
    local namespace="$1"
    
    log_debug "Creating resource quota for namespace: $namespace"
    
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ddd-workshop-quota
  namespace: $namespace
  labels:
    app.kubernetes.io/name: ddd-workshop
    app.kubernetes.io/component: resources
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.memory: "8Gi"
    persistentvolumeclaims: "5"
    pods: "10"
    services: "5"
    configmaps: "10"
    secrets: "10"
EOF
    
    log_debug "Resource quota created for namespace: $namespace"
}

# Create RBAC for user
create_user_rbac() {
    local username="$1"
    local namespace="$2"
    
    log_debug "Creating RBAC for user: $username in namespace: $namespace"
    
    # Create admin role binding for user in their namespace
    oc create rolebinding "${username}-admin" \
        --clusterrole=admin \
        --user="$username" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | oc apply -f -
    
    # Create service account for workshop operations
    oc create serviceaccount "workshop-sa" -n "$namespace" --dry-run=client -o yaml | oc apply -f -
    
    # Grant service account necessary permissions
    oc create rolebinding "workshop-sa-admin" \
        --clusterrole=admin \
        --serviceaccount="$namespace:workshop-sa" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | oc apply -f -
    
    log_debug "RBAC created for user: $username"
}

#######################################
# Batch User Operations
#######################################

# Create multiple users with namespaces and RBAC
create_workshop_users() {
    local user_prefix="$1"
    local num_users="$2"
    local password="$3"
    local namespace_suffix="${4:-devspaces}"
    
    log_step "Creating workshop users and environments..."
    print_script_header "Workshop User Creation" "Creating $num_users users with prefix '$user_prefix'"
    
    # Validate prerequisites
    check_openshift_login || return 1
    check_cluster_admin || return 1
    
    # Create HTPasswd users
    create_htpasswd_users "$user_prefix" "$num_users" "$password" || return 1
    
    # Create namespaces and RBAC for each user
    log_step "Setting up user namespaces and RBAC..."
    local created_namespaces=()
    
    for i in $(seq 1 "$num_users"); do
        local username="${user_prefix}${i}"
        log_info "Setting up environment for: $username"
        
        if create_user_namespace "$username" "$namespace_suffix"; then
            created_namespaces+=("${username}-${namespace_suffix}")
        else
            log_error "Failed to create namespace for user: $username"
            return 1
        fi
    done
    
    # Display summary
    log_success "Workshop users created successfully!"
    echo ""
    echo "=== Workshop User Summary ==="
    echo "✅ Users created: ${user_prefix}1 to ${user_prefix}${num_users}"
    echo "✅ Password: $password"
    echo "✅ Namespaces: ${created_namespaces[*]}"
    echo "✅ RBAC: Service accounts, roles, and bindings configured"
    echo "✅ Resource quotas: Applied for workshop workloads"
    echo ""
    
    # Display access information
    display_user_access_info "$user_prefix" "$num_users"
    
    return 0
}

# Display user access information
display_user_access_info() {
    local user_prefix="$1"
    local num_users="$2"
    
    log_step "Generating user access information..."
    
    # Get cluster domain and Dev Spaces URL
    local cluster_domain
    cluster_domain=$(get_cluster_domain)
    
    local devspaces_url=""
    if oc get route devspaces -n openshift-devspaces >/dev/null 2>&1; then
        devspaces_url="https://$(oc get route devspaces -n openshift-devspaces -o jsonpath='{.spec.host}')"
    elif oc get checluster devspaces -n openshift-devspaces >/dev/null 2>&1; then
        devspaces_url=$(oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}')
    else
        devspaces_url="https://devspaces.${cluster_domain}"
    fi
    
    echo "📊 Workshop Access Information:"
    echo "🌐 OpenShift Console: https://console-openshift-console.${cluster_domain}"
    echo "🚀 Dev Spaces URL: $devspaces_url"
    echo "📁 Workshop Repository: https://github.com/tosin2013/dddhexagonalworkshop.git"
    echo ""
    echo "👥 User Access Pattern:"
    echo "   Username: ${user_prefix}1, ${user_prefix}2, ..., ${user_prefix}${num_users}"
    echo "   Namespace: {username}-devspaces"
    echo ""
    echo "📋 Next Steps:"
    echo "1. Users can access Dev Spaces at: $devspaces_url"
    echo "2. Deploy workshop environments using:"
    echo "   ./scripts/deploy-workshop.sh --workshop --use-existing"
    echo "3. Users create workspaces with repository:"
    echo "   https://github.com/tosin2013/dddhexagonalworkshop.git"
}

#######################################
# User Cleanup Functions
#######################################

# Remove user and associated resources
remove_user() {
    local username="$1"
    local namespace_suffix="${2:-devspaces}"
    local namespace="${username}-${namespace_suffix}"
    
    log_info "Removing user: $username"
    
    # Remove namespace (this will remove all resources in it)
    if namespace_exists "$namespace"; then
        log_info "Removing namespace: $namespace"
        oc delete namespace "$namespace" --ignore-not-found=true
    else
        log_debug "Namespace not found: $namespace"
    fi
    
    # Note: HTPasswd user removal requires manual intervention to avoid
    # accidentally removing other users from the same htpasswd file
    log_info "Note: HTPasswd user '$username' not automatically removed"
    log_info "To remove from HTPasswd, manually edit the htpasswd secret in openshift-config namespace"
    
    log_success "User resources removed: $username"
}

# Remove multiple users
remove_workshop_users() {
    local users=("$@")
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_error "No users specified for removal"
        return 1
    fi
    
    log_step "Removing workshop users..."
    
    if ! confirm_action "Remove ${#users[@]} users and all their resources?"; then
        log_info "User removal cancelled"
        return 0
    fi
    
    for username in "${users[@]}"; do
        remove_user "$username"
    done
    
    log_success "Workshop user removal completed"
}

# Export functions for use in other scripts
# Validate user exists in HTPasswd
validate_user_exists() {
    local username="$1"

    if ! oc get secret htpasswd -n openshift-config >/dev/null 2>&1; then
        log_error "HTPasswd secret not found"
        return 1
    fi

    local htpasswd_users
    htpasswd_users=$(oc get secret htpasswd -n openshift-config -o jsonpath='{.data.htpasswd}' 2>/dev/null | base64 -d | cut -d: -f1 || echo "")

    if echo "$htpasswd_users" | grep -q "^${username}$"; then
        log_debug "User $username exists in HTPasswd"
        return 0
    else
        log_error "User $username does not exist in HTPasswd"
        return 1
    fi
}

export -f detect_existing_htpasswd_users get_detected_pattern_users get_detected_all_users
export -f create_htpasswd_users create_user_namespace create_user_resource_quota create_user_rbac
export -f create_workshop_users display_user_access_info remove_user remove_workshop_users
export -f validate_user_exists

# Mark as loaded
USER_MANAGEMENT_LOADED=true
# log_debug "User management library loaded"
