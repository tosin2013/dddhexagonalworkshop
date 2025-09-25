#!/bin/bash
# Multi-User Deployment Library for DDD Hexagonal Workshop
# Handles DevWorkspace deployment for multiple users
# Consolidates functionality from deploy-multi-user-workshop.sh

set -euo pipefail

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common-utils.sh
source "$SCRIPT_DIR/common-utils.sh"

# Configuration
readonly DEVWORKSPACE_API_VERSION="workspace.devfile.io/v1alpha2"
readonly WORKSHOP_REPOSITORY="https://github.com/tosin2013/dddhexagonalworkshop.git"
readonly DEVFILE_PATH="devfile-complete.yaml"

#######################################
# DevWorkspace Creation Functions
#######################################

# Create DevWorkspace for a user
create_user_devworkspace() {
    local username="$1"
    local namespace="${username}-devspaces"
    local workspace_name="ddd-workshop-${username}"
    
    log_debug "Creating DevWorkspace for user: $username"
    log_confidence "87" "DevWorkspace creation process"
    
    # Check if workspace already exists
    if oc get devworkspace "$workspace_name" -n "$namespace" >/dev/null 2>&1; then
        log_info "DevWorkspace already exists for user: $username"
        return 0
    fi
    
    # Create DevWorkspace
    cat <<EOF | oc apply -f -
apiVersion: $DEVWORKSPACE_API_VERSION
kind: DevWorkspace
metadata:
  name: $workspace_name
  namespace: $namespace
  labels:
    app.kubernetes.io/name: ddd-workshop
    app.kubernetes.io/component: devworkspace
    workshop.user: "$username"
spec:
  started: true
  routingClass: che
  template:
    projects:
      - name: ddd-workshop
        git:
          remotes:
            origin: "$WORKSHOP_REPOSITORY"
          checkoutFrom:
            revision: main
    components:
      - name: tools
        container:
          image: registry.access.redhat.com/ubi9/openjdk-21:1.20
          memoryLimit: 768Mi
          memoryRequest: 384Mi
          cpuLimit: 500m
          cpuRequest: 100m
          command: ['/bin/bash']
          args: ['-c', 'while true; do sleep 30; done']
          env:
            - name: MAVEN_OPTS
              value: "-Xmx384m"
            - name: QUARKUS_HTTP_HOST
              value: "0.0.0.0"
            - name: JAVA_HOME
              value: "/usr/lib/jvm/java-21-openjdk"
          endpoints:
            - name: http-8080
              targetPort: 8080
              exposure: public
              protocol: http
          volumeMounts:
            - name: m2
              path: /home/jboss/.m2
          sourceMapping: /projects
      
      - name: postgresql
        container:
          image: registry.redhat.io/rhel9/postgresql-16:latest
          memoryLimit: 384Mi
          memoryRequest: 192Mi
          cpuLimit: 200m
          cpuRequest: 100m
          env:
            - name: POSTGRESQL_USER
              value: "quarkus"
            - name: POSTGRESQL_PASSWORD
              value: "quarkus"
            - name: POSTGRESQL_DATABASE
              value: "quarkus"
            - name: POSTGRESQL_ADMIN_PASSWORD
              value: "quarkus"
          endpoints:
            - name: postgresql
              targetPort: 5432
              exposure: none
          volumeMounts:
            - name: postgresql-data
              path: /var/lib/pgsql/data
      
      - name: kafka
        container:
          image: bitnami/kafka:3.6
          memoryLimit: 768Mi
          memoryRequest: 384Mi
          cpuLimit: 300m
          cpuRequest: 150m
          env:
            - name: KAFKA_CFG_NODE_ID
              value: "1"
            - name: KAFKA_CFG_PROCESS_ROLES
              value: "controller,broker"
            - name: KAFKA_CFG_CONTROLLER_QUORUM_VOTERS
              value: "1@localhost:9093"
            - name: KAFKA_CFG_LISTENERS
              value: "PLAINTEXT://:9092,CONTROLLER://:9093"
            - name: KAFKA_CFG_ADVERTISED_LISTENERS
              value: "PLAINTEXT://localhost:9092"
            - name: KAFKA_CFG_CONTROLLER_LISTENER_NAMES
              value: "CONTROLLER"
            - name: KAFKA_CFG_LISTENER_SECURITY_PROTOCOL_MAP
              value: "CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT"
            - name: KAFKA_CFG_AUTO_CREATE_TOPICS_ENABLE
              value: "true"
            - name: KAFKA_CFG_OFFSETS_TOPIC_REPLICATION_FACTOR
              value: "1"
            - name: KAFKA_CFG_TRANSACTION_STATE_LOG_REPLICATION_FACTOR
              value: "1"
            - name: KAFKA_CFG_TRANSACTION_STATE_LOG_MIN_ISR
              value: "1"
            - name: KAFKA_HEAP_OPTS
              value: "-Xmx192m -Xms192m"
          endpoints:
            - name: kafka
              targetPort: 9092
              exposure: none
          volumeMounts:
            - name: kafka-data
              path: /bitnami/kafka
      
      - name: m2
        volume:
          ephemeral: true
      - name: postgresql-data
        volume:
          ephemeral: true
      - name: kafka-data
        volume:
          ephemeral: true
    
    commands:
      - id: check-env
        exec:
          label: "Check Environment"
          component: tools
          commandLine: |
            echo "=== Environment Check ==="
            java -version
            mvn -version || echo "Installing Maven..."
            timeout 3 bash -c '</dev/tcp/localhost/5432' && echo "✅ PostgreSQL OK"
            timeout 3 bash -c '</dev/tcp/localhost/9092' && echo "✅ Kafka OK"
          group:
            kind: run
            isDefault: true
      
      - id: dev-run
        exec:
          label: "Start Quarkus Dev Mode"
          component: tools
          commandLine: "cd /projects/ddd-workshop && mvn quarkus:dev"
          group:
            kind: run
      
      - id: compile
        exec:
          label: "Compile Project"
          component: tools
          commandLine: "cd /projects/ddd-workshop && mvn compile"
          group:
            kind: build
      
      - id: test
        exec:
          label: "Run Tests"
          component: tools
          commandLine: "cd /projects/ddd-workshop && mvn test"
          group:
            kind: test
EOF
    
    log_success "DevWorkspace created for user: $username"
    return 0
}

# Wait for DevWorkspace to be ready
wait_for_devworkspace_ready() {
    local username="$1"
    local namespace="${username}-devspaces"
    local workspace_name="ddd-workshop-${username}"
    local timeout="${2:-300}"
    
    log_info "Waiting for DevWorkspace to be ready: $workspace_name (timeout: ${timeout}s)"
    
    local elapsed=0
    while [ "$elapsed" -lt "$timeout" ]; do
        local phase
        phase=$(oc get devworkspace "$workspace_name" -n "$namespace" -o jsonpath='{.status.phase}' 2>/dev/null || echo "")
        
        case "$phase" in
            "Running")
                log_success "DevWorkspace is running: $workspace_name"
                return 0
                ;;
            "Failed")
                log_error "DevWorkspace failed: $workspace_name"
                oc get devworkspace "$workspace_name" -n "$namespace" -o yaml
                return 1
                ;;
            "Starting"|"Stopped"|"")
                log_debug "DevWorkspace phase: $phase"
                ;;
            *)
                log_debug "DevWorkspace phase: $phase"
                ;;
        esac
        
        echo -n "."
        sleep 10
        elapsed=$((elapsed + 10))
    done
    
    log_error "Timeout waiting for DevWorkspace to be ready: $workspace_name"
    return 1
}

#######################################
# Batch Deployment Functions
#######################################

# Deploy DevWorkspaces for multiple users
deploy_multi_user_devworkspaces() {
    local users=("$@")
    local incremental="${INCREMENTAL:-false}"
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_error "No users specified for DevWorkspace deployment"
        return 1
    fi
    
    log_step "Deploying DevWorkspaces for ${#users[@]} users..."
    log_confidence "85" "Multi-user DevWorkspace deployment"
    
    local deployed_count=0
    local failed_count=0
    local skipped_count=0
    
    for username in "${users[@]}"; do
        log_info "Processing DevWorkspace for user: $username"
        
        # Check if incremental deployment and workspace exists
        if [[ "$incremental" == "true" ]]; then
            local namespace="${username}-devspaces"
            local workspace_name="ddd-workshop-${username}"
            
            if oc get devworkspace "$workspace_name" -n "$namespace" >/dev/null 2>&1; then
                log_info "DevWorkspace already exists for $username, skipping..."
                ((skipped_count++))
                continue
            fi
        fi
        
        # Create DevWorkspace
        if create_user_devworkspace "$username"; then
            ((deployed_count++))
            log_success "DevWorkspace deployed for user: $username"
        else
            ((failed_count++))
            log_error "Failed to deploy DevWorkspace for user: $username"
        fi
    done
    
    # Summary
    echo ""
    echo "=== Multi-User DevWorkspace Deployment Summary ==="
    echo "✅ Deployed: $deployed_count"
    echo "⏭️  Skipped: $skipped_count"
    echo "❌ Failed: $failed_count"
    echo "📊 Total: ${#users[@]}"
    echo ""
    
    if [[ $failed_count -gt 0 ]]; then
        log_warn "$failed_count DevWorkspace deployments failed"
        return 1
    fi
    
    log_success "Multi-user DevWorkspace deployment completed"
    return 0
}

# Wait for multiple DevWorkspaces to be ready
wait_for_multi_user_devworkspaces() {
    local users=("$@")
    local timeout="${DEVWORKSPACE_TIMEOUT:-300}"
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_warn "No users specified for DevWorkspace readiness check"
        return 0
    fi
    
    log_step "Waiting for ${#users[@]} DevWorkspaces to be ready..."
    
    local ready_count=0
    local failed_count=0
    
    for username in "${users[@]}"; do
        if wait_for_devworkspace_ready "$username" "$timeout"; then
            ((ready_count++))
        else
            ((failed_count++))
        fi
    done
    
    echo ""
    echo "=== DevWorkspace Readiness Summary ==="
    echo "✅ Ready: $ready_count"
    echo "❌ Failed: $failed_count"
    echo "📊 Total: ${#users[@]}"
    echo ""
    
    if [[ $failed_count -gt 0 ]]; then
        log_warn "$failed_count DevWorkspaces failed to become ready"
        return 1
    fi
    
    log_success "All DevWorkspaces are ready"
    return 0
}

#######################################
# Cleanup Functions
#######################################

# Remove DevWorkspace for a user
remove_user_devworkspace() {
    local username="$1"
    local namespace="${username}-devspaces"
    local workspace_name="ddd-workshop-${username}"
    
    log_info "Removing DevWorkspace for user: $username"
    
    if oc get devworkspace "$workspace_name" -n "$namespace" >/dev/null 2>&1; then
        oc delete devworkspace "$workspace_name" -n "$namespace" --ignore-not-found=true
        log_success "DevWorkspace removed for user: $username"
    else
        log_debug "DevWorkspace not found for user: $username"
    fi
}

# Remove DevWorkspaces for multiple users
remove_multi_user_devworkspaces() {
    local users=("$@")
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_error "No users specified for DevWorkspace removal"
        return 1
    fi
    
    log_step "Removing DevWorkspaces for ${#users[@]} users..."
    
    if ! confirm_action "Remove DevWorkspaces for ${#users[@]} users?"; then
        log_info "DevWorkspace removal cancelled"
        return 0
    fi
    
    for username in "${users[@]}"; do
        remove_user_devworkspace "$username"
    done
    
    log_success "Multi-user DevWorkspace removal completed"
}

#######################################
# Status and Information Functions
#######################################

# Get DevWorkspace status for a user
get_devworkspace_status() {
    local username="$1"
    local namespace="${username}-devspaces"
    local workspace_name="ddd-workshop-${username}"
    
    if oc get devworkspace "$workspace_name" -n "$namespace" >/dev/null 2>&1; then
        local phase
        phase=$(oc get devworkspace "$workspace_name" -n "$namespace" -o jsonpath='{.status.phase}')
        echo "$phase"
    else
        echo "NotFound"
    fi
}

# Display multi-user deployment status
display_multi_user_status() {
    local users=("$@")
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_warn "No users specified for status display"
        return 0
    fi
    
    log_step "Multi-user deployment status..."
    
    echo ""
    echo "=== DevWorkspace Status ==="
    printf "%-15s %-15s %-10s\n" "User" "Namespace" "Status"
    echo "----------------------------------------"
    
    for username in "${users[@]}"; do
        local namespace="${username}-devspaces"
        local status
        status=$(get_devworkspace_status "$username")
        
        printf "%-15s %-15s %-10s\n" "$username" "$namespace" "$status"
    done
    
    echo ""
}

# Export functions for use in other scripts
export -f create_user_devworkspace wait_for_devworkspace_ready
export -f deploy_multi_user_devworkspaces wait_for_multi_user_devworkspaces
export -f remove_user_devworkspace remove_multi_user_devworkspaces
export -f get_devworkspace_status display_multi_user_status

log_debug "Multi-user deployment library loaded"
