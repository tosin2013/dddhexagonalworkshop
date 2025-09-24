#!/bin/bash
# PostgreSQL Health Check Script for OpenShift Dev Spaces
# This script checks if PostgreSQL is ready to accept connections

set -e

# Configuration
POSTGRES_HOST=${POSTGRES_HOST:-localhost}
POSTGRES_PORT=${POSTGRES_PORT:-5432}
POSTGRES_USER=${POSTGRESQL_USER:-quarkus}
POSTGRES_DB=${POSTGRESQL_DATABASE:-quarkus}
MAX_ATTEMPTS=${MAX_ATTEMPTS:-30}
SLEEP_INTERVAL=${SLEEP_INTERVAL:-2}

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

# Function to check if PostgreSQL is ready
check_postgresql_ready() {
    pg_isready -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1
}

# Function to check if PostgreSQL can accept queries
check_postgresql_query() {
    psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1
}

# Main health check function
main() {
    log_info "Starting PostgreSQL health check..."
    log_info "Host: $POSTGRES_HOST, Port: $POSTGRES_PORT, User: $POSTGRES_USER, Database: $POSTGRES_DB"
    
    local attempt=1
    
    while [ $attempt -le $MAX_ATTEMPTS ]; do
        log_info "Attempt $attempt/$MAX_ATTEMPTS: Checking PostgreSQL readiness..."
        
        if check_postgresql_ready; then
            log_info "PostgreSQL is accepting connections. Testing query execution..."
            
            if check_postgresql_query; then
                log_info "PostgreSQL is fully ready and accepting queries!"
                exit 0
            else
                log_warn "PostgreSQL is accepting connections but not ready for queries yet."
            fi
        else
            log_warn "PostgreSQL is not ready yet."
        fi
        
        if [ $attempt -lt $MAX_ATTEMPTS ]; then
            log_info "Waiting ${SLEEP_INTERVAL}s before next attempt..."
            sleep $SLEEP_INTERVAL
        fi
        
        ((attempt++))
    done
    
    log_error "PostgreSQL failed to become ready after $MAX_ATTEMPTS attempts."
    log_error "Please check PostgreSQL logs and configuration."
    exit 1
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "PostgreSQL Health Check Script"
        echo ""
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Environment Variables:"
        echo "  POSTGRES_HOST          PostgreSQL host (default: localhost)"
        echo "  POSTGRES_PORT          PostgreSQL port (default: 5432)"
        echo "  POSTGRESQL_USER        PostgreSQL user (default: quarkus)"
        echo "  POSTGRESQL_DATABASE    PostgreSQL database (default: quarkus)"
        echo "  MAX_ATTEMPTS           Maximum health check attempts (default: 30)"
        echo "  SLEEP_INTERVAL         Sleep interval between attempts (default: 2)"
        echo ""
        echo "Options:"
        echo "  --help, -h             Show this help message"
        echo "  --quick, -q            Quick check (single attempt)"
        echo "  --verbose, -v          Verbose output"
        exit 0
        ;;
    --quick|-q)
        MAX_ATTEMPTS=1
        ;;
    --verbose|-v)
        set -x
        ;;
esac

# Run main function
main
