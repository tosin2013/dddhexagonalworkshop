#!/bin/bash
# Help and Usage Functions for DDD Workshop Deployment Script

set -euo pipefail

#######################################
# Display usage information
# Arguments:
#   $1 - Script name
#   $2 - Script version
#   $3 - Script description
#######################################
show_usage() {
    local script_name="${1:-deploy-workshop.sh}"
    local script_version="${2:-1.0.0}"
    local script_description="${3:-Unified deployment script}"
    
    cat << EOF
$script_name v$script_version
$script_description

USAGE:
    $script_name <MODE> [OPTIONS]

MODES:
    --workshop              Deploy multi-user workshop environment
    --single-user           Deploy single-user development environment
    --cluster-setup         Setup cluster prerequisites (Dev Spaces, etc.)
    --test                  Run comprehensive testing suite

WORKSHOP MODE OPTIONS:
    --count NUMBER          Number of users to create (user1, user2, ...)
    --users-file FILE       File containing usernames (one per line)
    --users LIST            Comma-separated list of usernames
    --use-existing          Use existing HTPasswd users automatically
    --password PASSWORD     Password for created users (default: workshop123)
    --user-prefix PREFIX    Prefix for created users (default: user)

SINGLE-USER MODE OPTIONS:
    --namespace NAME        Target namespace (default: ddd-workshop)

COMMON OPTIONS:
    --cleanup               Remove all deployed resources
    --generate-urls         Generate access URLs only
    --dry-run               Show what would be done without executing
    --force                 Skip confirmation prompts
    --verbose               Enable verbose output
    --help                  Show this help message

EXAMPLES:
    # Multi-user workshop for 20 users
    $script_name --workshop --count 20

    # Workshop with specific users
    $script_name --workshop --users "alice,bob,charlie"

    # Workshop using existing HTPasswd users
    $script_name --workshop --use-existing

    # Single-user deployment
    $script_name --single-user --namespace my-workshop

    # Setup cluster prerequisites
    $script_name --cluster-setup

    # Test existing environment
    $script_name --test --workshop --users-file users.txt

    # Cleanup workshop environment
    $script_name --workshop --cleanup --users-file users.txt

    # Generate access URLs
    $script_name --workshop --generate-urls --use-existing

PREREQUISITES:
    - OpenShift cluster access (oc login completed)
    - Appropriate permissions for selected mode:
      * Workshop/Cluster-setup: cluster-admin
      * Single-user: namespace admin or self-provisioner
      * Test: read access to target resources

CONFIDENCE LEVELS:
    This script follows methodological pragmatism principles:
    - High confidence (>85%): Core functionality, well-tested patterns
    - Medium confidence (70-85%): Standard operations with validation
    - Low confidence (<70%): Experimental features, requires verification

EOF
}

#######################################
# Display script header
# Arguments:
#   $1 - Script name
#   $2 - Script description
#   $3 - Script version
#######################################
print_script_header() {
    local script_name="${1:-DDD Workshop Deployment}"
    local script_description="${2:-Unified deployment script}"
    local script_version="${3:-1.0.0}"
    
    echo "========================================"
    echo "$script_name v$script_version"
    echo "$script_description"
    echo "========================================"
    echo ""
}

# Export functions
export -f show_usage print_script_header
