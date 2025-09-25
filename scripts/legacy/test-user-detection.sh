#!/bin/bash
# Test script for enhanced user detection in deploy-to-redhat-cluster.sh
# This script helps validate the user detection functionality

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Test the enhanced deployment script
test_user_detection() {
    log_step "Testing enhanced user detection functionality..."
    
    # Check if logged into OpenShift
    if ! oc whoami &>/dev/null; then
        log_error "Not logged into OpenShift. Please run 'oc login' first."
        exit 1
    fi
    
    log_info "Current user: $(oc whoami)"
    log_info "Current server: $(oc whoami --show-server)"
    echo ""
    
    # Test 1: Detect existing users
    log_step "Test 1: Detecting existing users..."
    "$SCRIPT_DIR/deploy-to-redhat-cluster.sh" --detect-users
    echo ""
    
    # Test 2: Show comprehensive status
    log_step "Test 2: Showing comprehensive status..."
    "$SCRIPT_DIR/deploy-to-redhat-cluster.sh" --status
    echo ""
    
    # Test 3: Check cluster capabilities only
    log_step "Test 3: Checking cluster capabilities..."
    "$SCRIPT_DIR/deploy-to-redhat-cluster.sh" --check-only
    echo ""
    
    log_info "✅ All tests completed successfully!"
    echo ""
    echo "=== Next Steps ==="
    echo "1. If users exist: Deploy workshop infrastructure only"
    echo "2. If no users: Create users first, then deploy"
    echo "3. Use --help to see all available options"
}

# Show usage
usage() {
    cat << EOF
Test Script for Enhanced User Detection

USAGE:
    $0 [OPTIONS]

OPTIONS:
    --test              Run user detection tests
    --help              Show this help message

EXAMPLES:
    $0 --test           # Run all detection tests
    $0                  # Run all detection tests (default)

PREREQUISITES:
    - Must be logged into OpenShift cluster
    - OpenShift CLI (oc) must be available

EOF
}

# Parse command line arguments
case "${1:---test}" in
    --help|-h)
        usage
        exit 0
        ;;
    --test|"")
        test_user_detection
        ;;
    *)
        log_error "Unknown option: $1"
        usage
        exit 1
        ;;
esac
