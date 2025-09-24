#!/bin/bash
# Multi-User Workshop Deployment Script
# Deploys DDD Hexagonal Architecture Workshop for multiple users on OpenShift

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Global variables for detected users
declare -a DETECTED_HTPASSWD_USERS=()
declare -a DETECTED_USER_PATTERN_USERS=()

# Default values
USERS_FILE=""
USER_COUNT=0
USERS_LIST=""
NAMESPACE_PREFIX="devspaces"
CLEANUP=false
INCREMENTAL=false
GENERATE_URLS=false
DRY_RUN=false
VERBOSE=false
USE_EXISTING_USERS=false
DETECT_USERS_ONLY=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${GREEN}==>${NC} $1"
}

# Usage function
usage() {
    cat << EOF
Multi-User Workshop Deployment Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --users-file FILE       File containing usernames (one per line)
    --count NUMBER          Number of users to create (user1, user2, ...)
    --users LIST            Comma-separated list of usernames
    --use-existing          Automatically use existing HTPasswd users (user pattern only)
    --detect-users          Detect existing HTPasswd users and show them
    --namespace-prefix STR  Namespace prefix (default: ddd-workshop)
    --cleanup               Remove all user environments
    --incremental           Add users to existing deployment
    --generate-urls         Generate access URLs for users
    --dry-run               Show what would be done without executing
    --verbose               Enable verbose output
    --help                  Show this help message

EXAMPLES:
    # Deploy for 20 users
    $0 --count 20

    # Deploy for specific users
    $0 --users "alice,bob,charlie"

    # Deploy from users file
    $0 --users-file users.txt

    # Use existing HTPasswd users automatically
    $0 --use-existing

    # Detect existing users first
    $0 --detect-users

    # Generate access URLs
    $0 --generate-urls --users-file users.txt

    # Cleanup all environments
    $0 --cleanup --users-file users.txt

    # Dry run to see what would be created
    $0 --dry-run --count 10

PREREQUISITES:
    - OpenShift cluster with admin access
    - OpenShift Dev Spaces operator installed
    - Sufficient cluster resources (see documentation)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --users-file)
            USERS_FILE="$2"
            shift 2
            ;;
        --count)
            USER_COUNT="$2"
            shift 2
            ;;
        --users)
            USERS_LIST="$2"
            shift 2
            ;;
        --use-existing)
            USE_EXISTING_USERS=true
            shift
            ;;
        --detect-users)
            # Set flag to detect users after functions are defined
            DETECT_USERS_ONLY=true
            shift
            ;;
        --namespace-prefix)
            log_warning "Namespace prefix is fixed to 'devspaces' for compatibility"
            NAMESPACE_PREFIX="devspaces"
            shift 2
            ;;
        --cleanup)
            CLEANUP=true
            shift
            ;;
        --incremental)
            INCREMENTAL=true
            shift
            ;;
        --generate-urls)
            GENERATE_URLS=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Verbose logging
verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        log_info "$1"
    fi
}

# Detect existing HTPasswd users (focusing on "user" pattern)
detect_existing_htpasswd_users() {
    local silent_mode="${1:-false}"

    if [[ "$silent_mode" != "true" ]]; then
        log_step "Detecting existing HTPasswd users..."
    fi

    local htpasswd_users=()
    local user_pattern_users=()

    # Check if HTPasswd secret exists
    if oc get secret htpasswd -n openshift-config >/dev/null 2>&1; then
        # Extract all HTPasswd users
        while IFS= read -r user; do
            [[ -n "$user" ]] && htpasswd_users+=("$user")
        done < <(oc get secret htpasswd -n openshift-config -o jsonpath='{.data.htpasswd}' 2>/dev/null | base64 -d | cut -d: -f1 || true)

        # Filter for "user" pattern users only (user1, user2, etc.)
        for user in "${htpasswd_users[@]}"; do
            if [[ "$user" =~ ^user[0-9]+$ ]]; then
                user_pattern_users+=("$user")
            fi
        done

        if [[ "$silent_mode" != "true" ]]; then
            log_info "Found ${#htpasswd_users[@]} total HTPasswd users"
            log_info "Found ${#user_pattern_users[@]} 'user' pattern users: ${user_pattern_users[*]}"
        fi

        # Check for existing user namespaces
        local existing_namespaces=()
        for user in "${user_pattern_users[@]}"; do
            if oc get namespace "${user}-devspaces" >/dev/null 2>&1; then
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
    DETECTED_USER_PATTERN_USERS=("${user_pattern_users[@]}")
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."

    # Check if logged into OpenShift
    if ! oc whoami &>/dev/null; then
        log_error "Not logged into OpenShift. Please run 'oc login' first."
        exit 1
    fi

    # Check cluster admin permissions
    if ! oc auth can-i '*' '*' --all-namespaces &>/dev/null; then
        log_error "Cluster admin permissions required for multi-user deployment."
        exit 1
    fi

    # Check if Dev Spaces operator is installed
    if ! oc get csv -n openshift-operators | grep -q devspaces; then
        log_warning "OpenShift Dev Spaces operator not found. Installing..."
        if [[ "$DRY_RUN" == "false" ]]; then
            "$SCRIPT_DIR/setup-cluster-devspaces.sh"
        fi
    fi

    log_success "Prerequisites check completed"
}

# Build user list (enhanced with automatic detection)
build_user_list() {
    local users=()

    # First, detect existing HTPasswd users (silent mode to avoid output in user list)
    detect_existing_htpasswd_users "true"

    if [[ -n "$USERS_FILE" ]]; then
        if [[ ! -f "$USERS_FILE" ]]; then
            log_error "Users file not found: $USERS_FILE"
            exit 1
        fi
        while IFS= read -r line; do
            [[ -n "$line" ]] && users+=("$line")
        done < "$USERS_FILE"
    elif [[ $USER_COUNT -gt 0 ]]; then
        for ((i=1; i<=USER_COUNT; i++)); do
            users+=("user$i")
        done
    elif [[ -n "$USERS_LIST" ]]; then
        IFS=',' read -ra users <<< "$USERS_LIST"
    elif [[ "$USE_EXISTING_USERS" == "true" ]] || [[ ${#DETECTED_USER_PATTERN_USERS[@]} -gt 0 && -z "$USERS_FILE" && $USER_COUNT -eq 0 && -z "$USERS_LIST" ]]; then
        # Automatically use detected "user" pattern users if no other specification
        if [[ ${#DETECTED_USER_PATTERN_USERS[@]} -gt 0 ]]; then
            users=("${DETECTED_USER_PATTERN_USERS[@]}")
            log_info "🎯 Automatically using ${#users[@]} detected HTPasswd users: ${users[*]}" >&2
        else
            log_error "No existing 'user' pattern users found in HTPasswd. Use --count N to create users."
            exit 1
        fi
    else
        log_error "Must specify users via --users-file, --count, --users, or --use-existing"
        exit 1
    fi

    if [[ ${#users[@]} -eq 0 ]]; then
        log_error "No users specified"
        exit 1
    fi

    echo "${users[@]}"
}

# Create namespace for user
create_user_namespace() {
    local username="$1"
    local namespace="${username}-${NAMESPACE_PREFIX}"
    
    verbose_log "Creating namespace: $namespace"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would create namespace: $namespace"
        return
    fi
    
    # Create namespace
    oc create namespace "$namespace" --dry-run=client -o yaml | oc apply -f -
    
    # Add labels
    oc label namespace "$namespace" \
        app.kubernetes.io/name=ddd-workshop \
        app.kubernetes.io/component=user-environment \
        workshop.user="$username" \
        --overwrite
    
    # Create resource quota (compatible with Dev Spaces - no CPU limits requirement)
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ddd-workshop-quota
  namespace: $namespace
  labels:
    app: ddd-workshop
    component: resources
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
    
    # Create role binding for user
    oc create rolebinding "${username}-admin" \
        --clusterrole=admin \
        --user="$username" \
        --namespace="$namespace" \
        --dry-run=client -o yaml | oc apply -f -
}

# Deploy workspace for user
deploy_user_workspace() {
    local username="$1"
    local namespace="${username}-${NAMESPACE_PREFIX}"
    
    verbose_log "Deploying workspace for user: $username"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "Would deploy workspace for user: $username in namespace: $namespace"
        return
    fi
    
    # Create DevWorkspace
    cat <<EOF | oc apply -f -
apiVersion: workspace.devfile.io/v1alpha2
kind: DevWorkspace
metadata:
  name: ddd-workshop-${username}
  namespace: $namespace
  labels:
    app.kubernetes.io/name: ddd-workshop
    workshop.user: "$username"
spec:
  started: true
  routingClass: che
  template:
    projects:
      - name: ddd-workshop
        git:
          remotes:
            origin: "https://github.com/tosin2013/dddhexagonalworkshop.git"
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
EOF
}

# Generate access URLs
generate_access_urls() {
    local users=($1)
    local cluster_domain
    local devspaces_base_url

    cluster_domain=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}')

    # Dynamically detect Dev Spaces URL
    if oc get route devspaces -n openshift-devspaces >/dev/null 2>&1; then
        devspaces_base_url="https://$(oc get route devspaces -n openshift-devspaces -o jsonpath='{.spec.host}')"
    elif oc get checluster devspaces -n openshift-devspaces >/dev/null 2>&1; then
        devspaces_base_url=$(oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}')
    else
        # cluster_domain already includes "apps.", so just prepend "devspaces."
        devspaces_base_url="https://devspaces.${cluster_domain}"
    fi

    log_step "Generating access URLs for ${#users[@]} users..."

    echo ""
    echo "=== Workshop Access URLs ==="
    echo ""

    for username in "${users[@]}"; do
        local devspaces_url="${devspaces_base_url}/#https://github.com/tosin2013/dddhexagonalworkshop.git&devfilePath=devfile-complete.yaml"
        echo "User: $username"
        echo "  Dev Spaces: $devspaces_url"
        echo "  Namespace: ${username}-${NAMESPACE_PREFIX}"
        echo ""
    done
    
    echo "=== Instructions for Users ==="
    echo "1. Click your Dev Spaces URL above"
    echo "2. Login with your OpenShift credentials"
    echo "3. Wait for workspace to start (2-3 minutes)"
    echo "4. Run 'check-env' command to verify services"
    echo "5. Start with Module 01: 01-End-to-End-DDD/01-Events.md"
    echo ""
}

# Cleanup user environments
cleanup_environments() {
    local users=($1)
    
    log_step "Cleaning up environments for ${#users[@]} users..."
    
    for username in "${users[@]}"; do
        local namespace="${username}-${NAMESPACE_PREFIX}"
        
        if oc get namespace "$namespace" &>/dev/null; then
            log_info "Removing namespace: $namespace"
            if [[ "$DRY_RUN" == "false" ]]; then
                oc delete namespace "$namespace" --ignore-not-found=true
            fi
        else
            verbose_log "Namespace not found: $namespace"
        fi
    done
    
    log_success "Cleanup completed"
}

# Main deployment function
deploy_multi_user() {
    local users=($1)
    
    log_step "Deploying workshop for ${#users[@]} users..."
    
    for username in "${users[@]}"; do
        log_info "Processing user: $username"
        
        if [[ "$INCREMENTAL" == "true" ]]; then
            local namespace="${username}-${NAMESPACE_PREFIX}"
            if oc get namespace "$namespace" &>/dev/null; then
                log_warning "Namespace $namespace already exists, skipping..."
                continue
            fi
        fi
        
        create_user_namespace "$username"
        deploy_user_workspace "$username"
        
        log_success "Deployed environment for user: $username"
    done
    
    log_success "Multi-user deployment completed"
}

# Main execution
main() {
    echo "=== Multi-User Workshop Deployment ==="
    echo "Repository: https://github.com/tosin2013/dddhexagonalworkshop.git"
    echo "Author: Tosin Akinsoho <takinosh@redhat.com>"
    echo ""

    # Handle detect-users-only case
    if [[ "$DETECT_USERS_ONLY" == "true" ]]; then
        detect_existing_htpasswd_users
        log_info "Detection completed. Found ${#DETECTED_USER_PATTERN_USERS[@]} 'user' pattern users."
        if [[ ${#DETECTED_USER_PATTERN_USERS[@]} -gt 0 ]]; then
            log_info "Detected users: ${DETECTED_USER_PATTERN_USERS[*]}"
        fi
        exit 0
    fi

    # Build user list
    users=($(build_user_list))
    log_info "Processing ${#users[@]} users: ${users[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warning "DRY RUN MODE - No changes will be made"
    fi
    
    # Check prerequisites
    check_prerequisites
    
    # Execute requested action
    if [[ "$CLEANUP" == "true" ]]; then
        cleanup_environments "${users[*]}"
    elif [[ "$GENERATE_URLS" == "true" ]]; then
        generate_access_urls "${users[*]}"
    else
        deploy_multi_user "${users[*]}"
        echo ""
        generate_access_urls "${users[*]}"
    fi
    
    log_success "Operation completed successfully!"
}

# Execute main function
main "$@"
