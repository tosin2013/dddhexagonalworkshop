# ADR-0006: RBAC and Service Account Configuration for OpenShift Dev Spaces

## Status
Proposed

## Context

OpenShift Dev Spaces workspaces run with specific security contexts and require proper Role-Based Access Control (RBAC) configuration. The DevWorkspace controller validates devfiles and enforces security policies through admission webhooks. Workshop participants need appropriate permissions to:

1. Create and manage their own workspaces
2. Access sidecar containers (PostgreSQL, Kafka)
3. Perform development tasks without security violations
4. Maintain isolation between different workshop participants

### Current Issues
- DevWorkspace admission webhook validation errors
- Potential permission issues for sidecar container access
- Need for proper service account configuration
- Security context constraints compliance

## Decision

We will implement a comprehensive RBAC and service account strategy for the DDD Hexagonal Architecture Workshop:

### 1. Workshop Service Account
Create a dedicated service account for workshop workspaces with minimal required permissions:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ddd-workshop-sa
  namespace: {user-namespace}
  labels:
    app: ddd-workshop
    component: rbac
```

### 2. Role and RoleBinding
Define specific permissions for workshop activities:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ddd-workshop-role
  namespace: {user-namespace}
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps", "secrets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log", "pods/exec"]
  verbs: ["get", "create"]
- apiGroups: ["workspace.devfile.io"]
  resources: ["devworkspaces"]
  verbs: ["get", "list", "watch", "update", "patch"]
```

### 3. Security Context Constraints
Ensure compatibility with OpenShift's restricted-v2 SCC:

```yaml
# In devfile.yaml - container security context
securityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  capabilities:
    drop:
    - ALL
  seccompProfile:
    type: RuntimeDefault
```

### 4. DevWorkspace Template Updates
Update the devfile to reference the service account:

```yaml
# In devfile.yaml
metadata:
  attributes:
    controller.devfile.io/storage-type: per-workspace
    controller.devfile.io/scc: restricted-v2
spec:
  template:
    attributes:
      controller.devfile.io/merge-union: true
    components:
      - name: quarkus-dev
        attributes:
          controller.devfile.io/service-account-name: ddd-workshop-sa
```

## Consequences

### Positive
- **Enhanced Security**: Proper RBAC ensures minimal required permissions
- **Compliance**: Meets OpenShift security requirements and best practices
- **Isolation**: Each workshop participant has isolated permissions
- **Validation**: DevWorkspace admission webhooks will accept properly configured workspaces
- **Auditability**: Clear permission boundaries for workshop activities

### Negative
- **Complexity**: Additional RBAC configuration required for deployment
- **Maintenance**: Service accounts and roles need to be managed per namespace
- **Setup Time**: Additional steps required for workshop environment preparation

### Neutral
- **Documentation**: Clear RBAC requirements documented for workshop administrators
- **Troubleshooting**: Easier to diagnose permission-related issues

## Implementation Plan

### Phase 1: Service Account Creation
1. Create workshop-specific service account template
2. Define minimal required permissions
3. Test with restricted-v2 SCC

### Phase 2: DevWorkspace Integration
1. Update devfile to reference service account
2. Add security context specifications
3. Validate admission webhook acceptance

### Phase 3: Multi-User Setup
1. Create namespace-scoped RBAC templates
2. Implement user isolation patterns
3. Document deployment procedures

### Phase 4: Validation and Testing
1. Test workspace creation with new RBAC
2. Validate sidecar container functionality
3. Confirm multi-user isolation

## Compliance and Security

### OpenShift Security Context Constraints
- Use `restricted-v2` SCC (default for most workloads)
- No privileged containers required
- All containers run as non-root users
- Capabilities dropped to minimum required

### Workshop Security Boundaries
- Each user namespace has isolated RBAC
- Service accounts scoped to workshop activities
- No cluster-level permissions required
- Sidecar containers follow same security constraints

## Monitoring and Observability

### RBAC Monitoring
- Track service account usage
- Monitor permission denials
- Audit workshop access patterns

### Security Compliance
- Regular SCC compliance checks
- Permission boundary validation
- Security context verification

## References
- [OpenShift Security Context Constraints](https://docs.openshift.com/container-platform/latest/authentication/managing-security-context-constraints.html)
- [DevWorkspace Operator Documentation](https://github.com/devfile/devworkspace-operator)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)
- ADR-0001: Inner Loop Development Architecture
- ADR-0002: Development Infrastructure Sidecar Pattern

## Author
Tosin Akinsoho <takinosh@redhat.com>

## Date
2025-08-02
