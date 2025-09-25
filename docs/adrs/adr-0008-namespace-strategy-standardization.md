# ADR-0008: Namespace Strategy Standardization

## Status
Accepted

## Context

The DDD Hexagonal Architecture Workshop had conflicting namespace patterns that caused deployment issues:

1. **`userX-devspaces`** pattern (from `create-workshop-users.sh`)
   - Follows OpenShift Dev Spaces conventions
   - Compatible with Dev Spaces default namespace template `<username>-devspaces`
   - Works with existing HTPasswd users
   - No resource quota conflicts

2. **`ddd-workshop-userX`** pattern (from `deploy-multi-user-workshop.sh`)
   - Custom workshop-specific naming
   - Caused resource quota issues with `che-gateway` container
   - Required CPU limits for all containers
   - Conflicted with Dev Spaces automatic workspace creation

## Problem

Users experienced:
- Workspaces created in wrong namespaces
- Resource quota failures: "must specify limits.cpu for: che-gateway"
- Permission errors when accessing Maven repositories
- Confusion about which script to use for deployment

## Decision

**We standardize on the `userX-devspaces` namespace pattern exclusively.**

### Implementation:

1. **Remove all `ddd-workshop-userX` namespace references** from:
   - `deploy-multi-user-workshop.sh`
   - Documentation
   - Helm charts
   - Test scripts

2. **Use `userX-devspaces` pattern** for:
   - All user workshop environments
   - DevWorkspace deployments
   - Resource quotas and RBAC
   - Documentation examples

3. **Deployment workflow**:
   - Use `create-workshop-users.sh` to create namespaces and RBAC
   - Users create workspaces via Dev Spaces UI
   - Workspaces automatically deploy to correct `userX-devspaces` namespace

## Consequences

### Positive:
- ✅ Eliminates namespace conflicts
- ✅ Follows OpenShift Dev Spaces best practices
- ✅ No resource quota CPU limits issues
- ✅ Compatible with existing HTPasswd users
- ✅ Simpler deployment workflow
- ✅ Clear documentation and user instructions

### Negative:
- ❌ Need to update existing scripts and documentation
- ❌ `deploy-multi-user-workshop.sh` needs significant refactoring
- ❌ Some existing `ddd-workshop-userX` namespaces may need cleanup

## Implementation Plan

1. **Phase 1**: Update documentation to reflect standardized approach
2. **Phase 2**: Refactor `deploy-multi-user-workshop.sh` to use `userX-devspaces` pattern
3. **Phase 3**: Clean up any existing `ddd-workshop-userX` namespaces
4. **Phase 4**: Update test scripts and validation tools

## Validation

The standardized approach should:
- [ ] Create workspaces in `userX-devspaces` namespaces only
- [ ] Work with existing HTPasswd users
- [ ] Not require CPU limits for `che-gateway`
- [ ] Allow proper Maven repository access
- [ ] Provide clear user instructions

## References

- OpenShift Dev Spaces Documentation: Namespace Templates
- ADR-0006: RBAC and Service Account Configuration
- Issue: Resource quota CPU limits conflict with che-gateway container
