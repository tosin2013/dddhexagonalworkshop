#!/bin/bash
# Comprehensive Test Script for DDD Hexagonal Workshop
# This script validates all user stories and acceptance criteria

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TEST_RESULTS_DIR="$PROJECT_ROOT/test-results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

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
TESTS_SKIPPED=0

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local expected_result="${3:-0}"
    
    ((TESTS_TOTAL++))
    log_test "Running: $test_name"
    
    if eval "$test_command" >/dev/null 2>&1; then
        local result=0
    else
        local result=$?
    fi
    
    if [ $result -eq $expected_result ]; then
        log_info "✅ PASS: $test_name"
        ((TESTS_PASSED++))
        echo "PASS,$test_name,$(date)" >> "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
        return 0
    else
        log_error "❌ FAIL: $test_name (expected: $expected_result, got: $result)"
        ((TESTS_FAILED++))
        echo "FAIL,$test_name,$(date),$result" >> "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
        return 1
    fi
}

# Function to skip a test
skip_test() {
    local test_name="$1"
    local reason="$2"
    
    ((TESTS_TOTAL++))
    ((TESTS_SKIPPED++))
    log_warn "⏭️  SKIP: $test_name ($reason)"
    echo "SKIP,$test_name,$(date),$reason" >> "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create test results directory
    mkdir -p "$TEST_RESULTS_DIR"
    
    # Initialize CSV file
    echo "Status,Test Name,Timestamp,Details" > "$TEST_RESULTS_DIR/test_results_$TIMESTAMP.csv"
    
    # Set environment variables
    export PROJECT_SOURCE="${PROJECT_SOURCE:-$PROJECT_ROOT}"
    export QUARKUS_HOST="${QUARKUS_HOST:-localhost}"
    export QUARKUS_PORT="${QUARKUS_PORT:-8080}"
    export POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
    export POSTGRES_PORT="${POSTGRES_PORT:-5432}"
    export KAFKA_HOST="${KAFKA_HOST:-localhost}"
    export KAFKA_PORT="${KAFKA_PORT:-9092}"
    
    log_info "Test environment setup complete"
}

# AC-001: Environment Startup Tests
test_environment_startup() {
    log_info "Testing AC-001: Environment Startup"
    
    # Test PostgreSQL availability
    run_test "PostgreSQL Port Accessible" "nc -z $POSTGRES_HOST $POSTGRES_PORT"
    
    # Test Kafka availability
    run_test "Kafka Port Accessible" "nc -z $KAFKA_HOST $KAFKA_PORT"
    
    # Test Quarkus application port
    run_test "Quarkus Port Accessible" "nc -z $QUARKUS_HOST $QUARKUS_PORT"
    
    # Test database connection
    if command -v psql >/dev/null 2>&1; then
        run_test "PostgreSQL Database Connection" "PGPASSWORD=workshop psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U attendee -d conference -c 'SELECT 1;'"
    else
        skip_test "PostgreSQL Database Connection" "psql not available"
    fi
    
    # Test Kafka broker
    if command -v kafka-broker-api-versions.sh >/dev/null 2>&1; then
        run_test "Kafka Broker API" "kafka-broker-api-versions.sh --bootstrap-server $KAFKA_HOST:$KAFKA_PORT"
    else
        skip_test "Kafka Broker API" "kafka tools not available"
    fi
}

# AC-002: Development Workflow Tests
test_development_workflow() {
    log_info "Testing AC-002: Development Workflow"
    
    # Test Maven wrapper availability
    for module in "01-End-to-End-DDD/module-01-code" "02-Value-Objects/module-02-code" "03-Anticorruption-Layer/module-03-code"; do
        if [ -f "$PROJECT_ROOT/$module/mvnw" ]; then
            run_test "Maven Wrapper Available ($module)" "test -x $PROJECT_ROOT/$module/mvnw"
        else
            skip_test "Maven Wrapper Available ($module)" "module not found"
        fi
    done
    
    # Test compilation (if in a module directory)
    if [ -f "pom.xml" ]; then
        run_test "Project Compilation" "./mvnw compile -q"
    else
        skip_test "Project Compilation" "not in module directory"
    fi
}

# AC-003: Resource Management Tests
test_resource_management() {
    log_info "Testing AC-003: Resource Management"
    
    # Test memory usage
    local memory_usage
    memory_usage=$(free -m | awk 'NR==2{printf "%.1f", $3*100/$2}')
    if (( $(echo "$memory_usage < 80" | bc -l) )); then
        log_info "✅ PASS: Memory Usage ($memory_usage% < 80%)"
        ((TESTS_PASSED++))
        ((TESTS_TOTAL++))
    else
        log_error "❌ FAIL: Memory Usage ($memory_usage% >= 80%)"
        ((TESTS_FAILED++))
        ((TESTS_TOTAL++))
    fi
    
    # Test CPU usage (average over 5 seconds)
    local cpu_usage
    cpu_usage=$(top -bn2 -d1 | grep "Cpu(s)" | tail -1 | awk '{print $2}' | cut -d'%' -f1)
    if (( $(echo "$cpu_usage < 80" | bc -l) )); then
        log_info "✅ PASS: CPU Usage ($cpu_usage% < 80%)"
        ((TESTS_PASSED++))
        ((TESTS_TOTAL++))
    else
        log_error "❌ FAIL: CPU Usage ($cpu_usage% >= 80%)"
        ((TESTS_FAILED++))
        ((TESTS_TOTAL++))
    fi
}

# AC-004: Container Orchestration Tests
test_container_orchestration() {
    log_info "Testing AC-004: Container Orchestration"
    
    # Test container startup sequence (if in OpenShift)
    if command -v oc >/dev/null 2>&1 && oc whoami >/dev/null 2>&1; then
        local namespace
        namespace=$(oc project -q 2>/dev/null || echo "")
        
        if [ -n "$namespace" ]; then
            # Test PostgreSQL deployment
            run_test "PostgreSQL Deployment Ready" "oc get deployment ddd-workshop-postgresql -n $namespace -o jsonpath='{.status.readyReplicas}' | grep -q '1'"
            
            # Test Kafka deployment
            run_test "Kafka Deployment Ready" "oc get deployment ddd-workshop-kafka -n $namespace -o jsonpath='{.status.readyReplicas}' | grep -q '1'"
            
            # Test Quarkus deployment
            run_test "Quarkus Deployment Ready" "oc get deployment ddd-workshop-quarkus -n $namespace -o jsonpath='{.status.readyReplicas}' | grep -q '1'"
        else
            skip_test "Container Orchestration Tests" "not in OpenShift environment"
        fi
    else
        skip_test "Container Orchestration Tests" "OpenShift CLI not available or not logged in"
    fi
}

# AC-005: Data Persistence Tests
test_data_persistence() {
    log_info "Testing AC-005: Data Persistence"
    
    # Test database table creation
    if command -v psql >/dev/null 2>&1; then
        run_test "Database Tables Exist" "PGPASSWORD=workshop psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U attendee -d conference -c '\\dt' | grep -q 'public'"
    else
        skip_test "Database Tables Exist" "psql not available"
    fi
    
    # Test Kafka topic creation (if tools available)
    if command -v kafka-topics.sh >/dev/null 2>&1; then
        run_test "Kafka Topics Available" "kafka-topics.sh --bootstrap-server $KAFKA_HOST:$KAFKA_PORT --list | wc -l | grep -v '^0$'"
    else
        skip_test "Kafka Topics Available" "kafka tools not available"
    fi
}

# AC-006: Module Compatibility Tests
test_module_compatibility() {
    log_info "Testing AC-006: Module Compatibility"
    
    # Test each module structure
    for module in "01-End-to-End-DDD/module-01-code" "02-Value-Objects/module-02-code" "03-Anticorruption-Layer/module-03-code"; do
        run_test "Module Structure ($module)" "test -d $PROJECT_ROOT/$module && test -f $PROJECT_ROOT/$module/pom.xml"
    done
    
    # Test module-specific requirements
    run_test "Module 01 Classes" "find $PROJECT_ROOT/01-End-to-End-DDD/module-01-code/src -name '*.java' | wc -l | grep -v '^0$'"
    run_test "Module 02 Classes" "find $PROJECT_ROOT/02-Value-Objects/module-02-code/src -name '*.java' | wc -l | grep -v '^0$'"
    run_test "Module 03 Classes" "find $PROJECT_ROOT/03-Anticorruption-Layer/module-03-code/src -name '*.java' | wc -l | grep -v '^0$'"
}

# Application Health Tests
test_application_health() {
    log_info "Testing Application Health Endpoints"
    
    local base_url="http://$QUARKUS_HOST:$QUARKUS_PORT"
    
    if command -v curl >/dev/null 2>&1; then
        # Test health endpoint
        run_test "Health Endpoint" "curl -s -f $base_url/q/health"
        
        # Test liveness endpoint
        run_test "Liveness Endpoint" "curl -s -f $base_url/q/health/live"
        
        # Test readiness endpoint
        run_test "Readiness Endpoint" "curl -s -f $base_url/q/health/ready"
        
        # Test metrics endpoint
        run_test "Metrics Endpoint" "curl -s -f $base_url/q/metrics"
        
        # Test OpenAPI endpoint
        run_test "OpenAPI Endpoint" "curl -s -f $base_url/q/openapi"
    else
        skip_test "HTTP Endpoint Tests" "curl not available"
    fi
}

# Performance Tests
test_performance() {
    log_info "Testing Performance Characteristics"
    
    local base_url="http://$QUARKUS_HOST:$QUARKUS_PORT"
    
    if command -v curl >/dev/null 2>&1; then
        # Test response time
        local response_time
        response_time=$(curl -s -w "%{time_total}" -o /dev/null "$base_url/q/health" 2>/dev/null || echo "999")
        
        if (( $(echo "$response_time < 2.0" | bc -l) )); then
            log_info "✅ PASS: Response Time (${response_time}s < 2.0s)"
            ((TESTS_PASSED++))
            ((TESTS_TOTAL++))
        else
            log_error "❌ FAIL: Response Time (${response_time}s >= 2.0s)"
            ((TESTS_FAILED++))
            ((TESTS_TOTAL++))
        fi
    else
        skip_test "Performance Tests" "curl not available"
    fi
}

# Generate test report
generate_test_report() {
    local report_file="$TEST_RESULTS_DIR/test_report_$TIMESTAMP.md"
    
    cat > "$report_file" << EOF
# DDD Hexagonal Workshop Test Report

**Generated**: $(date)  
**Environment**: $(uname -a)  
**Test Duration**: $(($(date +%s) - START_TIME)) seconds

## Summary

- **Total Tests**: $TESTS_TOTAL
- **Passed**: $TESTS_PASSED
- **Failed**: $TESTS_FAILED
- **Skipped**: $TESTS_SKIPPED
- **Success Rate**: $(( TESTS_TOTAL > 0 ? (TESTS_PASSED * 100) / TESTS_TOTAL : 0 ))%

## Test Categories

### AC-001: Environment Startup
Tests that all containers start successfully within 3 minutes and can communicate.

### AC-002: Development Workflow
Tests that Maven and Quarkus development mode work correctly.

### AC-003: Resource Management
Tests that resource usage stays within acceptable limits.

### AC-004: Container Orchestration
Tests proper startup sequence and container health.

### AC-005: Data Persistence
Tests database and messaging data handling.

### AC-006: Module Compatibility
Tests that all workshop modules are properly structured.

## Detailed Results

See: test_results_$TIMESTAMP.csv

## Recommendations

EOF

    if [ $TESTS_FAILED -gt 0 ]; then
        echo "⚠️ **Action Required**: $TESTS_FAILED tests failed. Review the detailed results and address issues before workshop delivery." >> "$report_file"
    else
        echo "✅ **Ready for Workshop**: All critical tests passed. Environment is ready for participants." >> "$report_file"
    fi
    
    log_info "Test report generated: $report_file"
}

# Main test execution
main() {
    local START_TIME
    START_TIME=$(date +%s)
    
    log_info "🧪 Starting DDD Hexagonal Workshop Environment Tests"
    log_info "Timestamp: $(date)"
    echo ""
    
    setup_test_environment
    echo ""
    
    test_environment_startup
    echo ""
    
    test_development_workflow
    echo ""
    
    test_resource_management
    echo ""
    
    test_container_orchestration
    echo ""
    
    test_data_persistence
    echo ""
    
    test_module_compatibility
    echo ""
    
    test_application_health
    echo ""
    
    test_performance
    echo ""
    
    generate_test_report
    
    # Final summary
    log_info "🏁 Test Execution Complete"
    echo "=================================="
    echo "Total Tests: $TESTS_TOTAL"
    echo "Passed: $TESTS_PASSED"
    echo "Failed: $TESTS_FAILED"
    echo "Skipped: $TESTS_SKIPPED"
    echo "Success Rate: $(( TESTS_TOTAL > 0 ? (TESTS_PASSED * 100) / TESTS_TOTAL : 0 ))%"
    echo "=================================="
    
    if [ $TESTS_FAILED -gt 0 ]; then
        log_error "❌ Some tests failed. Review results before workshop delivery."
        exit 1
    else
        log_info "✅ All tests passed! Environment is ready for workshop."
        exit 0
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "DDD Hexagonal Workshop Environment Test Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h             Show this help message"
        echo "  --quick                Run only critical tests"
        echo "  --report-only          Generate report from existing results"
        echo "  --cleanup              Clean up test results"
        echo ""
        echo "Environment Variables:"
        echo "  QUARKUS_HOST           Quarkus host (default: localhost)"
        echo "  QUARKUS_PORT           Quarkus port (default: 8080)"
        echo "  POSTGRES_HOST          PostgreSQL host (default: localhost)"
        echo "  POSTGRES_PORT          PostgreSQL port (default: 5432)"
        echo "  KAFKA_HOST             Kafka host (default: localhost)"
        echo "  KAFKA_PORT             Kafka port (default: 9092)"
        exit 0
        ;;
    --quick)
        # Override functions for quick testing
        test_development_workflow() { log_info "Skipping development workflow tests (quick mode)"; }
        test_resource_management() { log_info "Skipping resource management tests (quick mode)"; }
        test_performance() { log_info "Skipping performance tests (quick mode)"; }
        ;;
    --report-only)
        generate_test_report
        exit 0
        ;;
    --cleanup)
        rm -rf "$TEST_RESULTS_DIR"
        log_info "Test results cleaned up"
        exit 0
        ;;
esac

# Run main function
main
