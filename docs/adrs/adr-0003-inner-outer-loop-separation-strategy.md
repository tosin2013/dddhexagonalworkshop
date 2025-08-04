# ADR-0003: Inner/Outer Loop Separation Strategy

## Status
Deprecated

**Reason**: Workshop now focuses exclusively on inner loop development experience using OpenShift Dev Spaces. Outer loop CI/CD pipeline complexity is not needed for educational objectives.

## Context
The DDD Hexagonal Architecture Workshop requires clear separation between fast development cycles (Inner Loop) and production deployment cycles (Outer Loop) to optimize for different workflow requirements and feedback speeds. 

Developers need immediate feedback for code changes during development, while production deployments require comprehensive testing, security scanning, and controlled release processes. The knowledge graph shows distinct workflow patterns with different tools, processes, and feedback mechanisms for each loop.

Traditional monolithic development approaches don't provide the necessary separation of concerns for modern cloud-native development practices.

Key requirements:
- Fast development cycles with immediate feedback (Inner Loop)
- Comprehensive quality gates for production deployment (Outer Loop)
- Clear workflow boundaries and responsibilities
- Optimized tooling for each development phase
- Educational value demonstrating modern DevOps practices

## Decision
Implement clear architectural separation between Inner Loop (OpenShift Dev Spaces) and Outer Loop (OpenShift Cluster) with distinct tooling, processes, and feedback mechanisms.

### Inner Loop (🔄 OpenShift Dev Spaces)
Focus on fast development cycles:

1. **Fast Development Cycles** with live reload and hot deploy
2. **Immediate Feedback** through integrated development tools
3. **Local Testing** and debugging capabilities
4. **Direct Code-to-Runtime** connectivity

**Tools & Components:**
- Quarkus Dev Mode with live reload
- VS Code/IntelliJ integrated development
- Maven and Git development tools
- PostgreSQL and Kafka development containers

### Outer Loop (🚀 OpenShift Cluster)
Focus on production-ready deployment:

1. **Comprehensive CI/CD Pipeline** with automated testing
2. **Security Scanning** and vulnerability assessment
3. **Controlled Deployment** to QA and production environments
4. **Monitoring and Observability** for production systems

**Pipeline Stages:**
- Container Build (S2I/Buildah)
- Unit Tests and Integration Tests
- Security Scan and Vulnerability Check
- Automated Deployment to QA
- Production deployment with monitoring

### Workflow Connections
As shown in knowledge graph:
```
Inner Loop → Outer Loop:
CODE -.-> QUARKUS_DEV (Inner Loop)
COMMIT --> BUILD (Outer Loop)

Environment Progression:
SERVICES_DEV -.-> APP_QA -.-> APP_PROD
PG_DEV -.-> PG_QA -.-> PG_PROD
KAFKA_DEV -.-> KAFKA_QA -.-> KAFKA_PROD

Feedback Loops:
MONITORING -.-> DEBUG (Inner Loop)
OBSERVABILITY -.-> DEBUG (Inner Loop)
APP_QA -.-> TEST (Inner Loop)
```

## Consequences

### Positive Consequences
- **Optimized Workflows**: Each loop optimized for its specific requirements
- **Faster Development Cycles**: Inner Loop provides immediate feedback
- **Comprehensive Quality Gates**: Outer Loop ensures production readiness
- **Clear Separation of Concerns**: Distinct responsibilities and tooling
- **Better Developer Productivity**: Immediate feedback in development phase
- **Robust Production Process**: Proper validation and monitoring
- **Educational Value**: Demonstrates modern DevOps practices
- **Scalable Architecture**: Supports both development and production needs

### Negative Consequences
- **Increased Complexity**: Managing two distinct workflow patterns
- **Context Switching Overhead**: Developers must understand both loops
- **Different Toolsets Required**: Need expertise in multiple tool chains
- **Potential Environment Inconsistencies**: Development vs. production differences
- **Additional Infrastructure Overhead**: More systems to maintain
- **Learning Curve**: Workshop participants must understand both patterns

## Alternatives Considered

### Single Unified Development Pipeline
**Rejected**: Conflicting requirements for speed (development) vs. thoroughness (production) cannot be optimized simultaneously.

### Local Development Only
**Rejected**: Doesn't provide environment consistency, collaboration capabilities, or realistic production patterns.

### Production-First Development
**Rejected**: Slow feedback cycles severely impact developer productivity and learning effectiveness.

### Continuous Deployment Without Separation
**Rejected**: Lacks necessary quality gates and security requirements for enterprise environments.

## Implementation Notes

### Inner Loop Optimization
- Live reload response time < 3 seconds
- Hot deploy for code changes without restart
- Integrated debugging and testing tools
- Direct service connectivity for development

### Outer Loop Quality Gates
- Automated unit and integration testing
- Security vulnerability scanning
- Performance and load testing
- Deployment approval workflows

### Transition Points
- **Code Commit**: Triggers transition from Inner to Outer Loop
- **Deployment Success**: Enables feedback from Outer to Inner Loop
- **Issue Detection**: Routes problems back to Inner Loop for resolution

### Success Metrics
- Inner Loop: Development cycle time < 5 minutes
- Outer Loop: Deployment success rate > 95%
- Feedback Loop: Issue resolution time < 2 hours
- Educational: Participant understanding of both patterns

## Related Decisions
- [ADR-0001](adr-0001-inner-loop-development-architecture.md): Inner Loop Development Architecture
- [ADR-0002](adr-0002-development-infrastructure-sidecar-pattern.md): Development Infrastructure Sidecar Pattern
- ADR-0004: Environment Progression Strategy (planned)
- ADR-0005: Feedback Loop Architecture (planned)
- ADR-0006: CI/CD Pipeline Architecture (planned)

## Research Findings Integration

### Technical Feasibility Study Results (2025-08-02)
**Key Finding**: Inner/Outer Loop integration is feasible but requires standardized devfile configuration to prevent workflow failures.

**Integration Complexity Assessment**:
- **Primary Challenge**: Configuration management rather than technical incompatibility
- **Risk Factor**: Participant customizations causing pipeline failures
- **Success Enabler**: Standardized "golden path" devfile template

**Critical Success Factors**:
1. **Golden Path Devfile**: Version-controlled, centrally managed template for all participants
2. **Configuration Consistency**: Eliminate drift between development and CI/CD expectations
3. **Failure Prevention**: < 5% failure rate achievable through standardization

**Implementation Requirements**:
- **Standardized Template**: All participants use identical devfile structure
- **Limited Customization**: Restrict scope of permissible participant modifications
- **Version Control**: Central management of devfile templates and updates
- **Validation**: Automated checks for devfile compliance before pipeline execution

**Risk Mitigation**: R-03 (Medium Impact) - Inconsistent devfile configurations mitigated through enforced standardization.

## References
- Knowledge Graph: Inner/Outer Loop workflow visualization
- DevOps best practices: Loop separation patterns
- Workshop requirements: Educational effectiveness and production readiness
- OpenShift Dev Spaces and OpenShift Cluster documentation
- Technical Feasibility Study: `docs/research/reseach-response-2025-08-02.md`
