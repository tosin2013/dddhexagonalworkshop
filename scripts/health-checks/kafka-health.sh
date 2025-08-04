#!/bin/bash
# Kafka Health Check Script for OpenShift Dev Spaces
# This script checks if Kafka broker is ready to accept connections

set -e

# Configuration
KAFKA_HOST=${KAFKA_HOST:-localhost}
KAFKA_PORT=${KAFKA_PORT:-9092}
KAFKA_BOOTSTRAP_SERVERS=${KAFKA_BOOTSTRAP_SERVERS:-"$KAFKA_HOST:$KAFKA_PORT"}
MAX_ATTEMPTS=${MAX_ATTEMPTS:-30}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-3}
TEST_TOPIC=${TEST_TOPIC:-"health-check-topic"}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Function to check if Kafka broker is responding
check_kafka_broker() {
    kafka-broker-api-versions.sh --bootstrap-server "$KAFKA_BOOTSTRAP_SERVERS" >/dev/null 2>&1
}

# Function to check if Kafka can create topics
check_kafka_topics() {
    kafka-topics.sh --bootstrap-server "$KAFKA_BOOTSTRAP_SERVERS" --list >/dev/null 2>&1
}

# Function to test topic creation and deletion
test_kafka_operations() {
    local test_topic="$TEST_TOPIC-$(date +%s)"
    
    # Create test topic
    if kafka-topics.sh --bootstrap-server "$KAFKA_BOOTSTRAP_SERVERS" \
                      --create \
                      --topic "$test_topic" \
                      --partitions 1 \
                      --replication-factor 1 >/dev/null 2>&1; then
        
        # Delete test topic
        kafka-topics.sh --bootstrap-server "$KAFKA_BOOTSTRAP_SERVERS" \
                       --delete \
                       --topic "$test_topic" >/dev/null 2>&1
        return 0
    else
        return 1
    fi
}

# Function to check Zookeeper connectivity (if available)
check_zookeeper() {
    if command -v kafka-run-class.sh >/dev/null 2>&1; then
        kafka-run-class.sh kafka.tools.ZooKeeperShell localhost:2181 <<< "ls /" >/dev/null 2>&1
    else
        # Skip Zookeeper check if tools not available
        return 0
    fi
}

# Main health check function
main() {
    log_info "Starting Kafka health check..."
    log_info "Bootstrap servers: $KAFKA_BOOTSTRAP_SERVERS"
    
    local attempt=1
    
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        log_info "Attempt $attempt/$MAX_ATTEMPTS: Checking Kafka broker..."
        
        if check_kafka_broker; then
            log_info "Kafka broker is responding. Testing topic operations..."
            
            if check_kafka_topics; then
                log_info "Kafka topic operations are working."
                
                # Optional: Test topic creation/deletion
                if [ "${SKIP_TOPIC_TEST:-false}" != "true" ]; then
                    if test_kafka_operations; then
                        log_info "Kafka topic creation/deletion test passed."
                    else
                        log_warn "Kafka topic creation/deletion test failed, but broker is responsive."
                    fi
                fi
                
                log_info "Kafka is fully ready!"
                exit 0
            else
                log_warn "Kafka broker is responding but topic operations are not ready yet."
            fi
        else
            log_warn "Kafka broker is not responding yet."
        fi
        
        if [ $attempt -lt $MAX_ATTEMPTS ]; then
            log_info "Waiting ${SLEEP_INTERVAL}s before next attempt..."
            sleep $SLEEP_INTERVAL
        fi
        
        ((attempt++))
    done
    
    log_error "Kafka failed to become ready after $MAX_ATTEMPTS attempts."
    log_error "Please check Kafka logs and configuration."
    exit 1
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Kafka Health Check Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Environment Variables:"
        echo "  KAFKA_HOST             Kafka host (default: localhost)"
        echo "  KAFKA_PORT             Kafka port (default: 9092)"
        echo "  KAFKA_BOOTSTRAP_SERVERS Bootstrap servers (default: localhost:9092)"
        echo "  MAX_ATTEMPTS           Maximum health check attempts (default: 30)"
        echo "  SLEEP_INTERVAL         Sleep interval between attempts (default: 3)"
        echo "  TEST_TOPIC             Test topic prefix (default: health-check-topic)"
        echo "  SKIP_TOPIC_TEST        Skip topic creation test (default: false)"
        echo ""
        echo "Options:"
        echo "  --help, -h             Show this help message"
        echo "  --quick, -q            Quick check (single attempt)"
        echo "  --verbose, -v          Verbose output"
        echo "  --skip-topic-test      Skip topic creation/deletion test"
        exit 0
        ;;
    --quick|-q)
        MAX_ATTEMPTS=1
        ;;
    --verbose|-v)
        set -x
        ;;
    --skip-topic-test)
        SKIP_TOPIC_TEST=true
        ;;
esac

# Run main function
main
