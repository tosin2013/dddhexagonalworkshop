#!/bin/bash
# Testing Framework for DDD Hexagonal Workshop
# Unified testing and validation for all deployment modes
# Consolidates functionality from test-* scripts

set -euo pipefail

# Source common utilities if not already loaded
if [[ -z "${COMMON_UTILS_LOADED:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=scripts/lib/common-utils.sh
    source "$SCRIPT_DIR/common-utils.sh"
fi

# Source user management if not already loaded
if [[ -z "${USER_MANAGEMENT_LOADED:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    # shellcheck source=scripts/lib/user-management.sh
    source "$SCRIPT_DIR/user-management.sh"
fi

# Test configuration
TEST_RESULTS_DIR="${PROJECT_ROOT}/test-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Test categories
readonly TEST_CATEGORY_ENVIRONMENT="Environment"
readonly TEST_CATEGORY_CONNECTIVITY="Connectivity"
readonly TEST_CATEGORY_DEPLOYMENT="Deployment"
readonly TEST_CATEGORY_USER="User"
readonly TEST_CATEGORY_PERFORMANCE="Performance"

#######################################
# Test Execution Framework
#######################################

# Initialize test environment
init_test_environment() {
    log_step "Initializing test environment..."
    
    # Create test results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Initialize CSV file
    echo "Status,Category,Test Name,Timestamp,Details" > "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
    
    # Reset counters
    TESTS_TOTAL=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
    
    log_success "Test environment initialized"
}

# Run a test and track results
run_test() {
    local category="$1"
    local test_name="$2"
    local test_command="$3"
    local expected_result="${4:-0}"
    
    ((TESTS_TOTAL++))
    log_debug "Running test: [$category] $test_name"
    
    local result=0
    local output=""
    
    # Capture both exit code and output
    if output=$(eval "$test_command" 2>&1); then
        result=0
    else
        result=$?
    fi
    
    # Record result
    if [ "$result" -eq "$expected_result" ]; then
        log_success "✅ PASS: [$category] $test_name"
        ((TESTS_PASSED++))
        echo "PASS,$category,$test_name,$(date)," >> "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
        return 0
    else
        log_error "❌ FAIL: [$category] $test_name (expected: $expected_result, got: $result)"
        log_debug "Test output: $output"
        ((TESTS_FAILED++))
        echo "FAIL,$category,$test_name,$(date),$result" >> "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
        return 1
    fi
}

# Skip a test with reason
skip_test() {
    local category="$1"
    local test_name="$2"
    local reason="$3"
    
    ((TESTS_TOTAL++))
    ((TESTS_SKIPPED++))
    log_warn "⏭️  SKIP: [$category] $test_name ($reason)"
    echo "SKIP,$category,$test_name,$(date),$reason" >> "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
}

#######################################
# Environment Tests
#######################################

# Test basic environment prerequisites
test_environment_prerequisites() {
    log_step "Testing environment prerequisites..."
    
    # Test required commands
    local required_commands=("oc" "curl" "nc")
    for cmd in "${required_commands[@]}"; do
        run_test "$TEST_CATEGORY_ENVIRONMENT" "Command Available: $cmd" "command -v $cmd"
    done
    
    # Test OpenShift login
    run_test "$TEST_CATEGORY_ENVIRONMENT" "OpenShift Login" "check_openshift_login"
    
    # Test cluster connectivity
    run_test "$TEST_CATEGORY_ENVIRONMENT" "Cluster API Connectivity" "oc version --client=false"
}

# Test service connectivity
test_service_connectivity() {
    local postgres_host="${1:-localhost}"
    local postgres_port="${2:-5432}"
    local kafka_host="${3:-localhost}"
    local kafka_port="${4:-9092}"
    local quarkus_host="${5:-localhost}"
    local quarkus_port="${6:-8080}"
    
    log_step "Testing service connectivity..."
    
    # Test PostgreSQL
    run_test "$TEST_CATEGORY_CONNECTIVITY" "PostgreSQL Port" "nc -z $postgres_host $postgres_port"
    
    if command_exists psql; then
        run_test "$TEST_CATEGORY_CONNECTIVITY" "PostgreSQL Connection" \
            "PGPASSWORD=quarkus psql -h $postgres_host -p $postgres_port -U quarkus -d quarkus -c 'SELECT 1;'"
    else
        skip_test "$TEST_CATEGORY_CONNECTIVITY" "PostgreSQL Connection" "psql not available"
    fi
    
    # Test Kafka
    run_test "$TEST_CATEGORY_CONNECTIVITY" "Kafka Port" "nc -z $kafka_host $kafka_port"
    
    # Test Quarkus application
    run_test "$TEST_CATEGORY_CONNECTIVITY" "Quarkus Port" "nc -z $quarkus_host $quarkus_port"
    
    if command_exists curl; then
        run_test "$TEST_CATEGORY_CONNECTIVITY" "Quarkus Health" \
            "curl -s -f http://$quarkus_host:$quarkus_port/q/health"
    else
        skip_test "$TEST_CATEGORY_CONNECTIVITY" "Quarkus Health" "curl not available"
    fi
}

#######################################
# User Environment Tests
#######################################

# Test individual user environment
test_user_environment() {
    local username="$1"
    local namespace_suffix="${2:-devspaces}"
    local namespace="${username}-${namespace_suffix}"
    
    log_step "Testing user environment: $username"
    
    # Test user exists in HTPasswd
    run_test "$TEST_CATEGORY_USER" "User Exists: $username" "validate_user_exists $username"
    
    # Test user namespace exists
    run_test "$TEST_CATEGORY_USER" "Namespace Exists: $namespace" "namespace_exists $namespace"
    
    # Test user RBAC
    run_test "$TEST_CATEGORY_USER" "User RBAC: $username" \
        "oc get rolebinding ${username}-admin -n $namespace"
    
    # Test resource quota
    run_test "$TEST_CATEGORY_USER" "Resource Quota: $namespace" \
        "oc get resourcequota ddd-workshop-quota -n $namespace"
    
    # Test existing workspaces
    local workspace_count
    workspace_count=$(oc get devworkspace -n "$namespace" --no-headers 2>/dev/null | wc -l || echo "0")
    
    if [[ $workspace_count -gt 0 ]]; then
        log_info "Found $workspace_count workspace(s) for user $username"
        run_test "$TEST_CATEGORY_USER" "Workspace Status: $username" \
            "oc get devworkspace -n $namespace -o jsonpath='{.items[0].status.phase}' | grep -E '(Running|Starting)'"
    else
        log_info "No existing workspaces for user $username (normal for new users)"
    fi
}

# Test multiple user environments
test_multi_user_environments() {
    local users=("$@")
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_warn "No users specified for multi-user testing"
        return 0
    fi
    
    log_step "Testing multi-user environments for ${#users[@]} users..."
    
    for username in "${users[@]}"; do
        test_user_environment "$username"
    done
    
    # Test user isolation
    log_step "Testing user isolation..."
    if [[ ${#users[@]} -ge 2 ]]; then
        local user1="${users[0]}"
        local user2="${users[1]}"
        
        # Test that user1 cannot access user2's namespace
        run_test "$TEST_CATEGORY_USER" "User Isolation: $user1 -> $user2" \
            "! oc auth can-i get pods --as=$user1 -n ${user2}-devspaces" 1
    fi
}

#######################################
# Deployment Tests
#######################################

# Test OpenShift Dev Spaces deployment
test_devspaces_deployment() {
    log_step "Testing OpenShift Dev Spaces deployment..."
    
    # Test Dev Spaces operator
    run_test "$TEST_CATEGORY_DEPLOYMENT" "Dev Spaces Operator" \
        "oc get csv -n openshift-operators | grep devspaces"
    
    # Test CheCluster
    run_test "$TEST_CATEGORY_DEPLOYMENT" "CheCluster Status" \
        "oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.chePhase}' | grep Active"
    
    # Test Dev Spaces route
    if oc get route devspaces -n openshift-devspaces >/dev/null 2>&1; then
        run_test "$TEST_CATEGORY_DEPLOYMENT" "Dev Spaces Route" \
            "oc get route devspaces -n openshift-devspaces"
        
        local devspaces_url
        devspaces_url="https://$(oc get route devspaces -n openshift-devspaces -o jsonpath='{.spec.host}')"
        
        if command_exists curl; then
            run_test "$TEST_CATEGORY_DEPLOYMENT" "Dev Spaces Accessibility" \
                "curl -s -k -I $devspaces_url | grep -E 'HTTP/[0-9.]+ (200|302)'"
        fi
    else
        skip_test "$TEST_CATEGORY_DEPLOYMENT" "Dev Spaces Route" "route not found"
    fi
}

# Test workshop deployment components
test_workshop_deployment() {
    local namespace="${1:-ddd-workshop}"
    
    log_step "Testing workshop deployment in namespace: $namespace"
    
    if ! namespace_exists "$namespace"; then
        skip_test "$TEST_CATEGORY_DEPLOYMENT" "Workshop Namespace" "namespace $namespace not found"
        return 0
    fi
    
    # Test common workshop components
    local components=("postgresql" "kafka")
    for component in "${components[@]}"; do
        local deployment_name="ddd-workshop-$component"
        
        if oc get deployment "$deployment_name" -n "$namespace" >/dev/null 2>&1; then
            run_test "$TEST_CATEGORY_DEPLOYMENT" "Deployment: $component" \
                "oc get deployment $deployment_name -n $namespace -o jsonpath='{.status.readyReplicas}' | grep -q '1'"
        else
            skip_test "$TEST_CATEGORY_DEPLOYMENT" "Deployment: $component" "deployment not found"
        fi
    done
}

#######################################
# Performance Tests
#######################################

# Test basic performance characteristics
test_performance() {
    local quarkus_host="${1:-localhost}"
    local quarkus_port="${2:-8080}"
    
    log_step "Testing performance characteristics..."
    
    if ! command_exists curl; then
        skip_test "$TEST_CATEGORY_PERFORMANCE" "Response Time" "curl not available"
        return 0
    fi
    
    local base_url="http://$quarkus_host:$quarkus_port"
    
    # Test response time
    local response_time
    response_time=$(curl -s -w "%{time_total}" -o /dev/null "$base_url/q/health" 2>/dev/null || echo "999")
    
    # Convert to integer for comparison (multiply by 100 to handle decimals)
    local response_time_int
    response_time_int=$(echo "$response_time * 100" | awk '{print int($1)}' 2>/dev/null || echo "999")

    if (( response_time_int < 500 )); then  # 5.0 seconds = 500 centiseconds
        log_success "✅ PASS: [Performance] Response Time (${response_time}s < 5.0s)"
        ((TESTS_PASSED++))
        ((TESTS_TOTAL++))
    else
        log_error "❌ FAIL: [Performance] Response Time (${response_time}s >= 5.0s)"
        ((TESTS_FAILED++))
        ((TESTS_TOTAL++))
    fi
}

#######################################
# Test Suites
#######################################

# Run comprehensive workshop test suite
run_workshop_test_suite() {
    local mode="${1:-single-user}"
    local users_list="${2:-}"
    
    log_step "Running workshop test suite (mode: $mode)..."
    init_test_environment
    
    # Common tests for all modes
    test_environment_prerequisites
    test_devspaces_deployment
    
    case "$mode" in
        "workshop"|"multi-user")
            if [[ -n "$users_list" ]]; then
                IFS=',' read -ra users <<< "$users_list"
                test_multi_user_environments "${users[@]}"
            else
                log_warn "No users specified for multi-user testing"
            fi
            ;;
        "single-user")
            local current_user
            current_user=$(oc whoami)
            test_user_environment "$current_user"
            ;;
        *)
            log_warn "Unknown test mode: $mode"
            ;;
    esac
    
    # Generate test report
    generate_test_report
}

# Generate comprehensive test report
generate_test_report() {
    local report_file="$TEST_RESULTS_DIR/test_report_$TIMESTAMP.md"
    local success_rate=0
    
    if [[ $TESTS_TOTAL -gt 0 ]]; then
        success_rate=$(( (TESTS_PASSED * 100) / TESTS_TOTAL ))
    fi
    
    cat > "$report_file" << EOF
# DDD Hexagonal Workshop Test Report

**Generated**: $(date)  
**Environment**: $(uname -a)  
**OpenShift User**: $(oc whoami 2>/dev/null || echo "N/A")  
**OpenShift Server**: $(oc whoami --show-server 2>/dev/null || echo "N/A")

## Summary

- **Total Tests**: $TESTS_TOTAL
- **Passed**: $TESTS_PASSED
- **Failed**: $TESTS_FAILED
- **Skipped**: $TESTS_SKIPPED
- **Success Rate**: ${success_rate}%

## Test Results

See detailed results in: test_results_$TIMESTAMP.csv

## Recommendations

EOF
    
    if [[ $TESTS_FAILED -gt 0 ]]; then
        echo "⚠️ **Action Required**: $TESTS_FAILED tests failed. Review the detailed results and address issues before workshop delivery." >> "$report_file"
    else
        echo "✅ **Ready for Workshop**: All critical tests passed. Environment is ready for participants." >> "$report_file"
    fi
    
    log_info "Test report generated: $report_file"
    
    # Display summary
    echo ""
    echo "=== Test Execution Summary ==="
    echo "Total Tests: $TESTS_TOTAL"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Skipped: $TESTS_SKIPPED"
    echo "Success Rate: ${success_rate}%"
    echo "==========================="
    
    return $TESTS_FAILED
}

# Export functions for use in other scripts
export -f init_test_environment run_test skip_test
export -f test_environment_prerequisites test_service_connectivity
export -f test_user_environment test_multi_user_environments
export -f test_devspaces_deployment test_workshop_deployment test_performance
export -f run_workshop_test_suite generate_test_report

# Mark as loaded
TESTING_FRAMEWORK_LOADED=true
# log_debug "Testing framework loaded"
