#!/bin/bash
# DDD Hexagonal Workshop - Unified Deployment Script
# Main entry point for all deployment modes: workshop, single-user, cluster-setup
# Consolidates functionality from multiple deployment scripts

set -euo pipefail

# Script metadata
readonly SCRIPT_VERSION="1.0.0"
readonly SCRIPT_NAME="DDD Workshop Deployment"
readonly SCRIPT_DESCRIPTION="Unified deployment script for multi-user workshops and single-user environments"

# Get script directory and source libraries
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# Source help functions first (lightweight)
# shellcheck source=scripts/lib/help-functions.sh
source "$LIB_DIR/help-functions.sh"

# Function to load heavy libraries only when needed
load_libraries() {
    # shellcheck source=scripts/lib/common-utils.sh
    source "$LIB_DIR/common-utils.sh"
    # shellcheck source=scripts/lib/user-management.sh
    source "$LIB_DIR/user-management.sh"
    # shellcheck source=scripts/lib/testing-framework.sh
    source "$LIB_DIR/testing-framework.sh"
    # shellcheck source=scripts/lib/cluster-setup.sh
    source "$LIB_DIR/cluster-setup.sh"
    # shellcheck source=scripts/lib/multi-user-deploy.sh
    source "$LIB_DIR/multi-user-deploy.sh"
    # shellcheck source=scripts/lib/single-user-deploy.sh
    source "$LIB_DIR/single-user-deploy.sh"
}

# Default configuration
DEFAULT_MODE=""
DEFAULT_NAMESPACE="ddd-workshop"
DEFAULT_USER_PREFIX="user"
DEFAULT_PASSWORD="workshop123"
DEFAULT_NAMESPACE_SUFFIX="devspaces"

# Global variables
MODE=""
NAMESPACE="$DEFAULT_NAMESPACE"
USER_PREFIX="$DEFAULT_USER_PREFIX"
PASSWORD="$DEFAULT_PASSWORD"
NAMESPACE_SUFFIX="$DEFAULT_NAMESPACE_SUFFIX"
USER_COUNT=0
USERS_FILE=""
USERS_LIST=""
DRY_RUN=false
FORCE=false
CLEANUP=false
TEST_ONLY=false
GENERATE_URLS=false
USE_EXISTING_USERS=false

#######################################
# Usage and Help Functions
#######################################

# Usage function now delegates to help-functions.sh
usage() {
    show_usage "$0" "$SCRIPT_VERSION" "$SCRIPT_DESCRIPTION"
}

#######################################
# Argument Parsing
#######################################

parse_arguments() {
    # Help is handled in main(), so we can assume we have arguments here

    while [[ $# -gt 0 ]]; do
        case $1 in
            --workshop)
                MODE="workshop"
                shift
                ;;
            --single-user)
                MODE="single-user"
                shift
                ;;
            --cluster-setup)
                MODE="cluster-setup"
                shift
                ;;
            --test)
                MODE="test"
                TEST_ONLY=true
                shift
                ;;
            --count)
                USER_COUNT="$2"
                validate_numeric_range "$USER_COUNT" 1 100 "user count"
                shift 2
                ;;
            --users-file)
                USERS_FILE="$2"
                validate_file "$USERS_FILE" "users file"
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
            --password)
                PASSWORD="$2"
                shift 2
                ;;
            --user-prefix)
                USER_PREFIX="$2"
                shift 2
                ;;
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --cleanup)
                CLEANUP=true
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
            --force)
                FORCE=true
                shift
                ;;
            --verbose)
                LOG_LEVEL=$LOG_LEVEL_DEBUG
                shift
                ;;
            --help|-h)
                # Help is handled in main(), this shouldn't be reached
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

    # Validate mode selection
    if [[ -z "$MODE" ]]; then
        log_error "No mode specified. Use --workshop, --single-user, --cluster-setup, or --test"
        usage
        exit 1
    fi

    log_debug "Parsed arguments - Mode: $MODE, Namespace: $NAMESPACE"
}

#######################################
# Mode-Specific Functions
#######################################

# Workshop mode implementation
execute_workshop_mode() {
    log_step "Executing workshop mode..."
    log_confidence "90" "Workshop mode deployment process"
    
    # Validate prerequisites
    check_openshift_login || exit 1
    check_cluster_admin || exit 1
    
    # Build user list
    local users=()
    if [[ -n "$USERS_FILE" ]]; then
        while IFS= read -r line; do
            [[ -n "$line" ]] && users+=("$line")
        done < "$USERS_FILE"
    elif [[ $USER_COUNT -gt 0 ]]; then
        for ((i=1; i<=USER_COUNT; i++)); do
            users+=("${USER_PREFIX}${i}")
        done
    elif [[ -n "$USERS_LIST" ]]; then
        IFS=',' read -ra users <<< "$USERS_LIST"
    elif [[ "$USE_EXISTING_USERS" == "true" ]]; then
        detect_existing_htpasswd_users
        mapfile -t users < <(get_detected_pattern_users)
        if [[ ${#users[@]} -eq 0 ]]; then
            log_error "No existing pattern users found. Use --count to create users."
            exit 1
        fi
        log_info "Using ${#users[@]} existing users: ${users[*]}"
    else
        log_error "Must specify users via --count, --users-file, --users, or --use-existing"
        exit 1
    fi
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_error "No users specified"
        exit 1
    fi
    
    log_info "Processing ${#users[@]} users: ${users[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        return 0
    fi
    
    # Execute requested action
    if [[ "$CLEANUP" == "true" ]]; then
        remove_workshop_users "${users[@]}"
    elif [[ "$GENERATE_URLS" == "true" ]]; then
        generate_workshop_urls "${users[@]}"
    else
        # Create users if they don't exist (unless using existing)
        if [[ "$USE_EXISTING_USERS" != "true" ]]; then
            create_workshop_users "$USER_PREFIX" "${#users[@]}" "$PASSWORD" "$NAMESPACE_SUFFIX"
        fi

        # Deploy DevWorkspaces for all users
        deploy_multi_user_devworkspaces "${users[@]}"

        # Generate access URLs
        generate_workshop_urls "${users[@]}"
    fi
}

# Single-user mode implementation
execute_single_user_mode() {
    log_step "Executing single-user mode..."
    log_confidence "85" "Single-user deployment process"
    
    # Validate prerequisites
    check_openshift_login || exit 1
    
    local current_user
    current_user=$(oc whoami)
    log_info "Deploying workshop for user: $current_user"
    log_info "Target namespace: $NAMESPACE"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        return 0
    fi
    
    if [[ "$CLEANUP" == "true" ]]; then
        cleanup_single_user_environment "$NAMESPACE"
    else
        # Deploy single-user environment
        deploy_single_user_environment "$NAMESPACE"
    fi
}

# Cluster setup mode implementation
execute_cluster_setup_mode() {
    log_step "Executing cluster setup mode..."
    log_confidence "95" "Cluster setup process (well-established)"
    
    # Validate prerequisites
    check_openshift_login || exit 1
    check_cluster_admin || exit 1
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_warn "DRY RUN MODE - No changes will be made"
        return 0
    fi
    
    # Use cluster setup library
    setup_cluster_for_workshop
}

# Test mode implementation
execute_test_mode() {
    log_step "Executing test mode..."
    log_confidence "88" "Testing framework implementation"
    
    # Validate prerequisites
    check_openshift_login || exit 1
    
    # Determine test mode based on other flags
    local test_mode="single-user"
    local users_for_test=""
    
    if [[ "$MODE" == "test" ]]; then
        # If other mode flags are present, use them for testing
        if [[ -n "$USERS_FILE" ]] || [[ $USER_COUNT -gt 0 ]] || [[ -n "$USERS_LIST" ]] || [[ "$USE_EXISTING_USERS" == "true" ]]; then
            test_mode="workshop"
            
            # Build user list for testing
            if [[ -n "$USERS_FILE" ]]; then
                users_for_test=$(tr '\n' ',' < "$USERS_FILE" | sed 's/,$//')
            elif [[ $USER_COUNT -gt 0 ]]; then
                local user_array=()
                for ((i=1; i<=USER_COUNT; i++)); do
                    user_array+=("${USER_PREFIX}${i}")
                done
                users_for_test=$(IFS=','; echo "${user_array[*]}")
            elif [[ -n "$USERS_LIST" ]]; then
                users_for_test="$USERS_LIST"
            elif [[ "$USE_EXISTING_USERS" == "true" ]]; then
                detect_existing_htpasswd_users
                local existing_users=()
                mapfile -t existing_users < <(get_detected_pattern_users)
                users_for_test=$(IFS=','; echo "${existing_users[*]}")
            fi
        fi
    fi
    
    log_info "Running test suite in $test_mode mode"
    if [[ -n "$users_for_test" ]]; then
        log_info "Testing users: $users_for_test"
    fi
    
    # Run comprehensive test suite
    run_workshop_test_suite "$test_mode" "$users_for_test"
}

# Generate workshop access URLs
generate_workshop_urls() {
    local users=("$@")
    
    log_step "Generating workshop access URLs..."
    
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
    
    echo ""
    echo "=== Workshop Access URLs ==="
    echo ""
    
    for username in "${users[@]}"; do
        local workspace_url="${devspaces_url}/#https://github.com/tosin2013/dddhexagonalworkshop.git&devfilePath=devfile-complete.yaml"
        echo "User: $username"
        echo "  Dev Spaces: $workspace_url"
        echo "  Namespace: ${username}-${NAMESPACE_SUFFIX}"
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

#######################################
# Main Execution
#######################################

main() {
    # Handle help first without loading heavy libraries
    if [[ $# -eq 0 ]] || [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        usage
        exit 0
    fi

    # Load libraries only when we need to do actual work
    load_libraries

    print_script_header "$SCRIPT_NAME" "$SCRIPT_DESCRIPTION" "$SCRIPT_VERSION"

    # Parse command line arguments
    parse_arguments "$@"
    
    # Execute based on mode
    case "$MODE" in
        "workshop")
            execute_workshop_mode
            ;;
        "single-user")
            execute_single_user_mode
            ;;
        "cluster-setup")
            execute_cluster_setup_mode
            ;;
        "test")
            execute_test_mode
            ;;
        *)
            log_error "Unknown mode: $MODE"
            exit 1
            ;;
    esac
    
    log_success "Operation completed successfully!"
}

# Execute main function with all arguments
main "$@"
