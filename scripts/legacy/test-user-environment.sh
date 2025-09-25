#!/bin/bash
# Test User Environment for Multi-User Workshop Deployment
# Simple script to verify a user's environment is ready

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "${BLUE}==> $1${NC}"; }

# Usage
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <username>"
    echo "Example: $0 user1"
    exit 1
fi

USERNAME="$1"
USER_NAMESPACE="${USERNAME}-devspaces"

echo "=== Workshop Environment Test ==="
echo "User: $USERNAME"
echo "Namespace: $USER_NAMESPACE"
echo ""

# Test 1: Check if user exists in HTPasswd
log_step "Checking if user exists..."
USER_EXISTS=false
if oc get secret htpasswd -n openshift-config >/dev/null 2>&1; then
    HTPASSWD_USERS=$(oc get secret htpasswd -n openshift-config -o jsonpath='{.data.htpasswd}' 2>/dev/null | base64 -d | cut -d: -f1 || echo "")
    if echo "$HTPASSWD_USERS" | grep -q "^${USERNAME}$"; then
        log_success "User $USERNAME exists in HTPasswd"
        USER_EXISTS=true
    else
        log_error "User $USERNAME does not exist in HTPasswd"
        log_info "Available users: $(echo "$HTPASSWD_USERS" | tr '\n' ' ')"
        log_info "Run: ./scripts/create-workshop-users.sh user 5 workshop123"
        exit 1
    fi
else
    log_error "HTPasswd secret not found"
    log_info "HTPasswd authentication may not be configured"
    exit 1
fi

# Test 2: Check namespace
log_step "Checking user namespace..."
if oc get namespace "$USER_NAMESPACE" >/dev/null 2>&1; then
    log_success "Namespace $USER_NAMESPACE exists"
else
    log_error "Namespace $USER_NAMESPACE missing"
    if [[ "$USER_EXISTS" == "true" ]]; then
        log_info "User exists but namespace missing. Run:"
        log_info "./scripts/create-workshop-users.sh user 5 workshop123"
    fi
    exit 1
fi

# Test 3: Get Dev Spaces URL
log_step "Getting Dev Spaces URL..."
DEVSPACES_URL=$(oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}' 2>/dev/null || echo "")
if [[ -n "$DEVSPACES_URL" ]]; then
    log_success "Dev Spaces URL: $DEVSPACES_URL"
else
    log_error "Dev Spaces not ready"
    exit 1
fi

# Test 4: Check existing workspaces
log_step "Checking existing workspaces..."
WORKSPACES=$(oc get devworkspace -n "$USER_NAMESPACE" --no-headers 2>/dev/null || echo "")
if [[ -n "$WORKSPACES" ]]; then
    echo "$WORKSPACES" | while read -r name id phase info; do
        if [[ "$phase" == "Running" ]]; then
            log_success "Workspace $name is running"
            log_info "Access: $info"
        elif [[ "$phase" == "Failed" ]]; then
            log_error "Workspace $name failed"
        else
            log_info "Workspace $name: $phase"
        fi
    done
else
    log_info "No existing workspaces (user will create new one)"
fi

# Test 5: Repository access
log_step "Testing repository access..."
if curl -s --head "https://github.com/tosin2013/dddhexagonalworkshop.git" | grep -q "200 OK"; then
    log_success "Repository accessible"
else
    log_warning "Repository may not be accessible"
fi

echo ""
echo "=== User Instructions ==="
echo "1. Access: $DEVSPACES_URL"
echo "2. Login: $USERNAME / <your-password>"
echo "3. Create Workspace:"
echo "   - Repository: https://github.com/tosin2013/dddhexagonalworkshop.git"
echo "   - Devfile: devfile-complete.yaml"
echo "4. Wait for startup (2-3 minutes)"
echo "5. Test: run 'check-env' command"
echo "6. Start: cd /projects/dddhexagonalworkshop/01-End-to-End-DDD/module-01-code"
echo ""

log_success "Environment test completed for $USERNAME"
