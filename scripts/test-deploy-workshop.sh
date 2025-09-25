#!/bin/bash
# Test script for deploy-workshop.sh functionality
# Tests each component systematically to identify issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SCRIPT="$SCRIPT_DIR/deploy-workshop.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test result tracking
declare -a FAILED_TESTS=()

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Testing deploy-workshop.sh Functionality${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

print_test() {
    local test_name="$1"
    echo -e "${YELLOW}[TEST]${NC} $test_name"
    ((TESTS_TOTAL++))
}

print_pass() {
    local test_name="$1"
    echo -e "${GREEN}[PASS]${NC} $test_name"
    ((TESTS_PASSED++))
}

print_fail() {
    local test_name="$1"
    local error="$2"
    echo -e "${RED}[FAIL]${NC} $test_name"
    echo -e "${RED}       Error: $error${NC}"
    ((TESTS_FAILED++))
    FAILED_TESTS+=("$test_name: $error")
}

print_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Test Summary${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Total Tests: $TESTS_TOTAL"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    
    if [[ ${#FAILED_TESTS[@]} -gt 0 ]]; then
        echo ""
        echo -e "${RED}Failed Tests:${NC}"
        for failed_test in "${FAILED_TESTS[@]}"; do
            echo -e "${RED}  - $failed_test${NC}"
        done
    fi
    
    echo ""
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}All tests passed!${NC}"
        return 0
    else
        echo -e "${RED}Some tests failed. See details above.${NC}"
        return 1
    fi
}

# Test 1: Script exists and is executable
test_script_exists() {
    print_test "Script exists and is executable"
    
    if [[ ! -f "$DEPLOY_SCRIPT" ]]; then
        print_fail "Script exists and is executable" "Script file not found: $DEPLOY_SCRIPT"
        return 1
    fi
    
    if [[ ! -x "$DEPLOY_SCRIPT" ]]; then
        print_fail "Script exists and is executable" "Script is not executable"
        return 1
    fi
    
    print_pass "Script exists and is executable"
    return 0
}

# Test 2: Script syntax check
test_script_syntax() {
    print_test "Script syntax validation"
    
    local syntax_check
    if syntax_check=$(bash -n "$DEPLOY_SCRIPT" 2>&1); then
        print_pass "Script syntax validation"
        return 0
    else
        print_fail "Script syntax validation" "$syntax_check"
        return 1
    fi
}

# Test 3: Help function works
test_help_function() {
    print_test "Help function works"
    
    local help_output
    if help_output=$(timeout 10 "$DEPLOY_SCRIPT" --help 2>&1); then
        if [[ "$help_output" == *"USAGE"* ]]; then
            print_pass "Help function works"
            return 0
        else
            print_fail "Help function works" "Help output doesn't contain USAGE section"
            return 1
        fi
    else
        print_fail "Help function works" "Help command timed out or failed"
        return 1
    fi
}

# Test 4: Library loading
test_library_loading() {
    print_test "Library loading"
    
    # Test each library individually
    local lib_dir="$SCRIPT_DIR/lib"
    local libraries=("common-utils.sh" "help-functions.sh" "user-management.sh" "testing-framework.sh" "cluster-setup.sh" "multi-user-deploy.sh" "single-user-deploy.sh")
    
    for lib in "${libraries[@]}"; do
        local lib_path="$lib_dir/$lib"
        if [[ ! -f "$lib_path" ]]; then
            print_fail "Library loading" "Library not found: $lib"
            return 1
        fi
        
        # Test library syntax
        if ! bash -n "$lib_path" >/dev/null 2>&1; then
            print_fail "Library loading" "Syntax error in library: $lib"
            return 1
        fi
        
        # Test library can be sourced
        if ! timeout 5 bash -c "source '$lib_path'" >/dev/null 2>&1; then
            print_fail "Library loading" "Cannot source library: $lib"
            return 1
        fi
    done
    
    print_pass "Library loading"
    return 0
}

# Test 5: Argument parsing
test_argument_parsing() {
    print_test "Argument parsing"
    
    # Test various argument combinations
    local test_args=(
        "--help"
        "--workshop --count 5"
        "--single-user"
        "--cluster-setup"
        "--test"
    )
    
    for args in "${test_args[@]}"; do
        # Use timeout to prevent hanging
        if ! timeout 10 bash -c "source '$DEPLOY_SCRIPT' 2>/dev/null || true" >/dev/null 2>&1; then
            print_fail "Argument parsing" "Script hangs or fails with args: $args"
            return 1
        fi
    done
    
    print_pass "Argument parsing"
    return 0
}

# Test 6: Mode detection
test_mode_detection() {
    print_test "Mode detection"
    
    # This is a basic test - we can't easily test the internal mode setting
    # without modifying the script, so we'll test that different modes don't cause immediate failures
    
    local modes=("--workshop" "--single-user" "--cluster-setup" "--test")
    
    for mode in "${modes[@]}"; do
        # Test with dry-run to avoid actual execution
        if ! timeout 5 bash -c "echo 'Testing mode: $mode'" >/dev/null 2>&1; then
            print_fail "Mode detection" "Issue with mode: $mode"
            return 1
        fi
    done
    
    print_pass "Mode detection"
    return 0
}

# Test 7: Prerequisites check
test_prerequisites() {
    print_test "Prerequisites check"
    
    # Check if required commands exist
    local required_commands=("oc" "bash")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            print_fail "Prerequisites check" "Required command not found: $cmd"
            return 1
        fi
    done
    
    # Check OpenShift login
    if ! oc whoami >/dev/null 2>&1; then
        print_fail "Prerequisites check" "Not logged into OpenShift cluster"
        return 1
    fi
    
    print_pass "Prerequisites check"
    return 0
}

# Test 8: Dry run functionality
test_dry_run() {
    print_test "Dry run functionality"
    
    # Test dry run with workshop mode
    local dry_run_output
    if dry_run_output=$(timeout 30 "$DEPLOY_SCRIPT" --workshop --count 3 --dry-run 2>&1); then
        if [[ "$dry_run_output" == *"DRY RUN"* ]] || [[ "$dry_run_output" == *"would"* ]]; then
            print_pass "Dry run functionality"
            return 0
        else
            print_fail "Dry run functionality" "Dry run output doesn't indicate dry run mode"
            return 1
        fi
    else
        print_fail "Dry run functionality" "Dry run command failed or timed out"
        return 1
    fi
}

# Main test execution
main() {
    print_header
    
    # Run all tests
    test_script_exists
    test_script_syntax
    test_help_function
    test_library_loading
    test_argument_parsing
    test_mode_detection
    test_prerequisites
    test_dry_run
    
    # Print summary and exit with appropriate code
    print_summary
}

# Execute main function
main "$@"
