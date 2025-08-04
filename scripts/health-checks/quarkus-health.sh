#!/bin/bash
# Quarkus Application Health Check Script for OpenShift Dev Spaces
# This script checks if Quarkus application is ready and healthy

set -e

# Configuration
QUARKUS_HOST=${QUARKUS_HOST:-localhost}
QUARKUS_PORT=${QUARKUS_PORT:-8080}
QUARKUS_BASE_URL=${QUARKUS_BASE_URL:-"http://$QUARKUS_HOST:$QUARKUS_PORT"}
MAX_ATTEMPTS=${MAX_ATTEMPTS:-30}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-2}

# Health check endpoints
HEALTH_LIVE_ENDPOINT="/q/health/live"
HEALTH_READY_ENDPOINT="/q/health/ready"
HEALTH_ENDPOINT="/q/health"

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

# Function to check HTTP endpoint
check_http_endpoint() {
    local endpoint="$1"
    local expected_status="${2:-200}"
    
    if command -v curl >/dev/null 2>&1; then
        local response_code
        response_code=$(curl -s -o /dev/null -w "%{http_code}" "$QUARKUS_BASE_URL$endpoint" 2>/dev/null || echo "000")
        [ "$response_code" = "$expected_status" ]
    elif command -v wget >/dev/null 2>&1; then
        wget -q --spider "$QUARKUS_BASE_URL$endpoint" >/dev/null 2>&1
    else
        log_error "Neither curl nor wget is available for health checks"
        return 1
    fi
}

# Function to get health check details
get_health_details() {
    local endpoint="$1"
    
    if command -v curl >/dev/null 2>&1; then
        curl -s "$QUARKUS_BASE_URL$endpoint" 2>/dev/null || echo "{\"status\":\"unknown\"}"
    else
        echo "{\"status\":\"unknown\"}"
    fi
}

# Function to check if Quarkus is live
check_quarkus_live() {
    check_http_endpoint "$HEALTH_LIVE_ENDPOINT"
}

# Function to check if Quarkus is ready
check_quarkus_ready() {
    check_http_endpoint "$HEALTH_READY_ENDPOINT"
}

# Function to check general health
check_quarkus_health() {
    check_http_endpoint "$HEALTH_ENDPOINT"
}

# Function to check database connectivity
check_database_connectivity() {
    local health_details
    health_details=$(get_health_details "$HEALTH_READY_ENDPOINT")
    
    if echo "$health_details" | grep -q "database"; then
        if echo "$health_details" | grep -q '"status":"UP"'; then
            return 0
        else
            return 1
        fi
    else
        # If no database health check is present, assume it's okay
        return 0
    fi
}

# Function to check Kafka connectivity
check_kafka_connectivity() {
    local health_details
    health_details=$(get_health_details "$HEALTH_READY_ENDPOINT")
    
    if echo "$health_details" | grep -q "kafka"; then
        if echo "$health_details" | grep -q '"status":"UP"'; then
            return 0
        else
            return 1
        fi
    else
        # If no Kafka health check is present, assume it's okay
        return 0
    fi
}

# Main health check function
main() {
    log_info "Starting Quarkus application health check..."
    log_info "Base URL: $QUARKUS_BASE_URL"
    
    local attempt=1
    
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        log_info "Attempt $attempt/$MAX_ATTEMPTS: Checking Quarkus application..."
        
        # Check if application is live
        if check_quarkus_live; then
            log_info "Quarkus application is live. Checking readiness..."
            
            # Check if application is ready
            if check_quarkus_ready; then
                log_info "Quarkus application is ready. Performing detailed health checks..."
                
                # Check database connectivity
                if check_database_connectivity; then
                    log_info "Database connectivity check passed."
                else
                    log_warn "Database connectivity check failed."
                fi
                
                # Check Kafka connectivity
                if check_kafka_connectivity; then
                    log_info "Kafka connectivity check passed."
                else
                    log_warn "Kafka connectivity check failed."
                fi
                
                # Final general health check
                if check_quarkus_health; then
                    log_info "Quarkus application is fully healthy!"
                    
                    # Display health details if verbose
                    if [ "${VERBOSE:-false}" = "true" ]; then
                        log_info "Health details:"
                        get_health_details "$HEALTH_ENDPOINT"
                    fi
                    
                    exit 0
                else
                    log_warn "General health check failed."
                fi
            else
                log_warn "Quarkus application is live but not ready yet."
            fi
        else
            log_warn "Quarkus application is not responding yet."
        fi
        
        if [ $attempt -lt $MAX_ATTEMPTS ]; then
            log_info "Waiting ${SLEEP_INTERVAL}s before next attempt..."
            sleep $SLEEP_INTERVAL
        fi
        
        ((attempt++))
    done
    
    log_error "Quarkus application failed to become healthy after $MAX_ATTEMPTS attempts."
    log_error "Please check application logs and configuration."
    
    # Show last health check details for debugging
    log_error "Last health check details:"
    get_health_details "$HEALTH_ENDPOINT"
    
    exit 1
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "Quarkus Application Health Check Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Environment Variables:"
        echo "  QUARKUS_HOST           Quarkus host (default: localhost)"
        echo "  QUARKUS_PORT           Quarkus port (default: 8080)"
        echo "  QUARKUS_BASE_URL       Quarkus base URL (default: http://localhost:8080)"
        echo "  MAX_ATTEMPTS           Maximum health check attempts (default: 30)"
        echo "  SLEEP_INTERVAL         Sleep interval between attempts (default: 2)"
        echo ""
        echo "Options:"
        echo "  --help, -h             Show this help message"
        echo "  --quick, -q            Quick check (single attempt)"
        echo "  --verbose, -v          Verbose output with health details"
        echo "  --live-only            Check only liveness endpoint"
        echo "  --ready-only           Check only readiness endpoint"
        exit 0
        ;;
    --quick|-q)
        MAX_ATTEMPTS=1
        ;;
    --verbose|-v)
        VERBOSE=true
        set -x
        ;;
    --live-only)
        # Override main function for live-only check
        main() {
            log_info "Checking Quarkus liveness only..."
            if check_quarkus_live; then
                log_info "Quarkus application is live!"
                exit 0
            else
                log_error "Quarkus application is not live."
                exit 1
            fi
        }
        ;;
    --ready-only)
        # Override main function for ready-only check
        main() {
            log_info "Checking Quarkus readiness only..."
            if check_quarkus_ready; then
                log_info "Quarkus application is ready!"
                exit 0
            else
                log_error "Quarkus application is not ready."
                exit 1
            fi
        }
        ;;
esac

# Run main function
main
