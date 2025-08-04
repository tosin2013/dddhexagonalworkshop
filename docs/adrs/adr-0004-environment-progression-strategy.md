# ADR-0004: Environment Progression Strategy

## Status
Deprecated

**Reason**: Workshop now uses a single complete development environment (devfile-complete.yaml) with all services. Multi-environment progression is not needed for workshop educational objectives.

## Context
The DDD Hexagonal Architecture Workshop requires a realistic environment progression strategy that mirrors enterprise development practices while supporting educational objectives. Workshop participants need to understand how applications progress from development through testing to production environments.

The knowledge graph demonstrates clear environment progression patterns with increasing complexity and monitoring capabilities at each stage. Each environment serves different purposes and has different requirements for performance, monitoring, and operational complexity.

Key requirements:
- Realistic enterprise environment progression patterns
- Educational value demonstrating DevOps best practices
- Risk reduction through gradual validation
- Appropriate monitoring and observability at each stage
- Support for workshop learning objectives

## Decision
Implement three-tier environment progression strategy: Development → QA → Production, with each environment having distinct characteristics, monitoring levels, and validation requirements.

### Development Environment (Dev)
**Purpose**: Fast development cycles and immediate feedback

**Characteristics:**
- PostgreSQL Container for development data
- Kafka Container for event testing
- Microservices in development mode
- Minimal monitoring and logging
- Direct developer access and debugging

**Tools:**
- Basic health checks
- Development-focused logging
- Direct service access for debugging

### QA Environment (Quality Assurance)
**Purpose**: Integration testing and quality validation

**Characteristics:**
- PostgreSQL QA Database with realistic data volumes
- Kafka Cluster for integration testing
- Application Pods in production-like configuration
- Monitoring with logging and metrics
- Automated testing and validation

**Tools:**
- Comprehensive monitoring and logging
- Automated integration testing
- Performance and load testing
- Security scanning validation

### Production Environment (Prod)
**Purpose**: Live system serving real users

**Characteristics:**
- PostgreSQL Production Database with high availability
- Kafka Cluster with production configuration
- Application Pods with production scaling
- Full observability stack with comprehensive monitoring
- Strict access controls and change management

**Tools:**
- Full observability (metrics, logging, tracing)
- Alerting and incident management
- Performance monitoring and optimization
- Security monitoring and compliance

### Environment Progression Flow
As shown in knowledge graph:
```
Development → QA → Production:
SERVICES_DEV -.-> APP_QA -.-> APP_PROD
PG_DEV -.-> PG_QA -.-> PG_PROD
KAFKA_DEV -.-> KAFKA_QA -.-> KAFKA_PROD

Monitoring Progression:
Basic Logging → MONITORING → OBSERVABILITY
```

## Consequences

### Positive Consequences
- **Risk Reduction**: Gradual validation reduces production deployment risks
- **Quality Assurance**: Comprehensive testing in QA environment
- **Realistic Learning**: Participants experience enterprise deployment patterns
- **Confidence Building**: Successful QA deployment builds confidence for production
- **Issue Detection**: Problems caught early in progression pipeline
- **Operational Excellence**: Each environment optimized for its purpose
- **Scalability**: Environment-specific configurations support different loads

### Negative Consequences
- **Increased Complexity**: Multiple environments require more infrastructure
- **Resource Overhead**: Each environment consumes compute and storage resources
- **Operational Burden**: More environments to maintain and monitor
- **Deployment Delays**: Progression through environments takes time
- **Configuration Drift**: Potential inconsistencies between environments
- **Cost Implications**: Multiple environments increase infrastructure costs

## Alternatives Considered

### Two-Tier Progression (Dev → Prod)
**Rejected**: Insufficient quality validation and too risky for production deployments without intermediate testing.

### Four-Tier Progression (Dev → Test → Stage → Prod)
**Rejected**: Too complex for workshop environment and diminishing returns on additional validation stages.

### Single Environment for All Purposes
**Rejected**: Doesn't demonstrate realistic enterprise practices and creates conflicts between development and production requirements.

### Environment-per-Participant
**Rejected**: Resource intensive and doesn't demonstrate collaborative development practices.

## Implementation Notes

### Environment Specifications

#### Development Environment
```yaml
resources:
  postgresql:
    memory: "512Mi"
    storage: "1Gi"
  kafka:
    memory: "1Gi"
    replicas: 1
  application:
    memory: "1Gi"
    replicas: 1
```

#### QA Environment
```yaml
resources:
  postgresql:
    memory: "2Gi"
    storage: "10Gi"
    backup: enabled
  kafka:
    memory: "2Gi"
    replicas: 3
  application:
    memory: "2Gi"
    replicas: 2
  monitoring:
    prometheus: enabled
    grafana: enabled
```

#### Production Environment
```yaml
resources:
  postgresql:
    memory: "4Gi"
    storage: "100Gi"
    backup: enabled
    highAvailability: enabled
  kafka:
    memory: "4Gi"
    replicas: 3
    persistence: enabled
  application:
    memory: "4Gi"
    replicas: 3
    autoscaling: enabled
  observability:
    prometheus: enabled
    grafana: enabled
    jaeger: enabled
    alertmanager: enabled
```

### Promotion Criteria
- **Dev → QA**: Code commit and basic unit tests pass
- **QA → Prod**: Integration tests pass, security scan clean, performance validation complete

### Success Metrics
- Environment promotion success rate > 95%
- QA environment catches > 90% of issues before production
- Production deployment success rate > 98%
- Mean time to recovery < 30 minutes

## Related Decisions
- [ADR-0003](adr-0003-inner-outer-loop-separation-strategy.md): Inner/Outer Loop Separation Strategy
- ADR-0005: Feedback Loop Architecture (planned)
- ADR-0009: Multi-Environment Monitoring Strategy (planned)

## References
- Knowledge Graph: Environment progression visualization
- Enterprise DevOps best practices
- Workshop requirements: Realistic deployment patterns
- OpenShift multi-environment deployment patterns
