#!/bin/bash
# Create Workshop Users with HTPasswd Authentication
# Creates multiple users for DDD Hexagonal Architecture Workshop

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Configuration
USER_PREFIX="${1:-user}"
NUM_USERS="${2:-5}"
PASSWORD="${3:-workshop123}"

echo "=== DDD Workshop User Creation ==="
echo "User prefix: $USER_PREFIX"
echo "Number of users: $NUM_USERS"
echo "Password: $PASSWORD"
echo

# Check cluster-admin privileges
echo "🔧 Checking cluster-admin privileges..."
if ! oc auth can-i '*' '*' --all-namespaces >/dev/null 2>&1; then
    echo "❌ Error: Cluster-admin privileges required"
    exit 1
fi
echo "✅ Cluster-admin privileges confirmed"

# Get current htpasswd secret
echo "🔧 Retrieving current htpasswd configuration..."
oc get secret htpasswd -n openshift-config -o jsonpath='{.data.htpasswd}' | base64 -d > /tmp/current-htpasswd 2>/dev/null || touch /tmp/current-htpasswd

# Create users in htpasswd file
echo "🔧 Creating workshop users..."
for i in $(seq 1 $NUM_USERS); do
    USERNAME="${USER_PREFIX}${i}"
    echo "Creating user: $USERNAME"
    
    # Add user to htpasswd file (or update if exists)
    htpasswd -bB /tmp/current-htpasswd "$USERNAME" "$PASSWORD" 2>/dev/null || {
        echo "Installing htpasswd-tools..."
        yum install -y httpd-tools >/dev/null 2>&1 || apt-get install -y apache2-utils >/dev/null 2>&1 || {
            echo "❌ Error: Could not install htpasswd tools"
            exit 1
        }
        htpasswd -bB /tmp/current-htpasswd "$USERNAME" "$PASSWORD"
    }
done

# Update the htpasswd secret
echo "🔧 Updating htpasswd secret..."
oc create secret generic htpasswd --from-file=htpasswd=/tmp/current-htpasswd --dry-run=client -o yaml | \
    oc replace -f - -n openshift-config

# Wait for authentication operator to sync
echo "🔧 Waiting for authentication operator to sync..."
sleep 10

# Create user namespaces and RBAC for each user
echo "🔧 Setting up user namespaces and RBAC..."
for i in $(seq 1 $NUM_USERS); do
    USERNAME="${USER_PREFIX}${i}"
    echo "Setting up environment for: $USERNAME"
    
    # Create user-specific namespace for Dev Spaces
    USER_NAMESPACE="${USERNAME}-devspaces"
    oc create namespace "$USER_NAMESPACE" --dry-run=client -o yaml | oc apply -f -
    
    # Label namespace for workshop
    oc label namespace "$USER_NAMESPACE" \
        app=ddd-workshop \
        workshop.redhat.com/user="$USERNAME" \
        workshop.redhat.com/author="takinosh" \
        --overwrite
    
    # Create workshop service account
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ddd-workshop-sa
  namespace: $USER_NAMESPACE
  labels:
    app: ddd-workshop
    component: rbac
    user: $USERNAME
  annotations:
    description: "Service account for DDD Hexagonal Architecture Workshop"
    workshop.redhat.com/author: "takinosh@redhat.com"
automountServiceAccountToken: true
EOF

    # Create workshop role
    cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ddd-workshop-role
  namespace: $USER_NAMESPACE
  labels:
    app: ddd-workshop
    component: rbac
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log", "pods/exec", "pods/portforward"]
  verbs: ["get", "create"]
- apiGroups: ["workspace.devfile.io"]
  resources: ["devworkspaces", "devworkspacetemplates"]
  verbs: ["get", "list", "watch", "update", "patch"]
- apiGroups: [""]
  resources: ["events"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "list", "watch"]
EOF

    # Create role binding
    cat <<EOF | oc apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ddd-workshop-binding
  namespace: $USER_NAMESPACE
  labels:
    app: ddd-workshop
    component: rbac
subjects:
- kind: ServiceAccount
  name: ddd-workshop-sa
  namespace: $USER_NAMESPACE
- kind: User
  name: $USERNAME
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ddd-workshop-role
  apiGroup: rbac.authorization.k8s.io
EOF

    # Create resource quota (Dev Spaces compatible)
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ddd-workshop-quota
  namespace: $USER_NAMESPACE
  labels:
    app: ddd-workshop
    component: resources
spec:
  hard:
    requests.cpu: "2"
    requests.memory: "4Gi"
    limits.memory: "8Gi"
    persistentvolumeclaims: "5"
    pods: "10"
    services: "5"
    configmaps: "10"
    secrets: "10"
EOF

    # Create limit range
    cat <<EOF | oc apply -f -
apiVersion: v1
kind: LimitRange
metadata:
  name: ddd-workshop-limits
  namespace: $USER_NAMESPACE
  labels:
    app: ddd-workshop
    component: resources
spec:
  limits:
  - default:
      memory: "1Gi"
    defaultRequest:
      cpu: "50m"
      memory: "128Mi"
    max:
      cpu: "1"
      memory: "2Gi"
    type: Container
  - max:
      storage: "5Gi"
    min:
      storage: "1Gi"
    type: PersistentVolumeClaim
EOF

done

# Clean up temporary file
rm -f /tmp/current-htpasswd

echo
echo "=== Workshop Users Created Successfully ==="
echo "✅ Users created: ${USER_PREFIX}1 to ${USER_PREFIX}${NUM_USERS}"
echo "✅ Password: $PASSWORD"
echo "✅ Namespaces: ${USER_PREFIX}1-devspaces to ${USER_PREFIX}${NUM_USERS}-devspaces"
echo "✅ RBAC: Service accounts, roles, and bindings configured"
echo "✅ Resource quotas: Applied for workshop workloads"
echo
echo "📊 Workshop Access Information:"

# Dynamically detect cluster domain and Dev Spaces URL
CLUSTER_DOMAIN=$(oc get ingresses.config.openshift.io cluster -o jsonpath='{.spec.domain}' 2>/dev/null || echo "<your-cluster-domain>")

# Try to get the actual Dev Spaces route if it exists
DEVSPACES_URL=""
if oc get route devspaces -n openshift-devspaces >/dev/null 2>&1; then
    DEVSPACES_URL=$(oc get route devspaces -n openshift-devspaces -o jsonpath='{.spec.host}' 2>/dev/null)
    DEVSPACES_URL="https://${DEVSPACES_URL}"
elif oc get checluster devspaces -n openshift-devspaces >/dev/null 2>&1; then
    DEVSPACES_URL=$(oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}' 2>/dev/null)
else
    # CLUSTER_DOMAIN already includes "apps.", so just prepend "devspaces."
    DEVSPACES_URL="https://devspaces.${CLUSTER_DOMAIN}"
fi

# Get OpenShift console URL dynamically
CONSOLE_URL=$(oc whoami --show-console 2>/dev/null || echo "https://console-openshift-console.apps.${CLUSTER_DOMAIN}")

echo "   • Dev Spaces URL: ${DEVSPACES_URL}"
echo "   • OpenShift Console: ${CONSOLE_URL}"
echo "   • Repository URL: https://github.com/tosin2013/dddhexagonalworkshop.git"
echo "   • Login: ${USER_PREFIX}1, ${USER_PREFIX}2, ..., ${USER_PREFIX}${NUM_USERS}"
echo "   • Password: $PASSWORD"
echo
echo "🚀 Users can now:"
echo "   1. Login to OpenShift: oc login -u ${USER_PREFIX}1 -p $PASSWORD"
echo "   2. Access Dev Spaces: ${DEVSPACES_URL}"
echo "   3. Create workspace with: https://github.com/tosin2013/dddhexagonalworkshop.git"
