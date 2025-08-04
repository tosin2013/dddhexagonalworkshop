# ADR-0002: Development Infrastructure Sidecar Pattern

## Status
Proposed

## Context
The DDD Hexagonal Architecture Workshop requires isolated but connected development services to support realistic microservices development patterns. Workshop participants need access to PostgreSQL for data persistence and Apache Kafka for event-driven architecture patterns, but these services must be isolated from the main development container while remaining easily accessible.

Traditional approaches of running all services in a single container create resource conflicts and don't reflect real-world deployment patterns. The development environment must support multiple concurrent users while maintaining service isolation and performance.

Key requirements:
- PostgreSQL database for domain entity persistence
- Apache Kafka for event-driven architecture and domain events
- Service isolation to prevent resource conflicts
- Realistic microservices development patterns
- Support for multiple concurrent workshop participants
- Easy service discovery and connectivity

## Decision
Implement development infrastructure using the sidecar pattern with dedicated containers for PostgreSQL and Kafka services.

Each development workspace includes:

1. **PostgreSQL Container** for development data persistence with dedicated storage
2. **Kafka Container** for event streaming and messaging testing
3. **Kubernetes Service Discovery** for reliable inter-service communication
4. **Resource Isolation** with appropriate CPU and memory limits
5. **Service Connectivity** through cluster-internal DNS names for realistic development patterns

Architecture as shown in knowledge graph:
```
Development Infrastructure:
├── PG_DEV[PostgreSQL Container - Development Data]
├── KAFKA_DEV[Kafka Container - Event Testing]  
└── SERVICES_DEV[Microservices - Development Mode]

Connectivity:
QUARKUS_DEV --> PG_DEV
QUARKUS_DEV --> KAFKA_DEV
QUARKUS_DEV --> SERVICES_DEV
```

## Consequences

### Positive Consequences
- **Better Resource Isolation**: Each service runs in its own container with dedicated resources
- **Realistic Development Environment**: Mirrors production microservices deployment patterns
- **Improved Service Reliability**: Service failures don't affect other components
- **Easier Debugging**: Individual service logs and metrics for troubleshooting
- **Scalable Architecture**: Supports multiple concurrent users without conflicts
- **Educational Value**: Participants learn real-world service architecture patterns
- **Performance Optimization**: Services can be tuned independently
- **Data Isolation**: Each participant has their own database instance

### Negative Consequences
- **Increased Complexity**: Service orchestration and startup sequencing required
- **Additional Resource Overhead**: Multiple containers consume more memory and CPU
- **Network Latency**: Inter-service communication through network stack
- **Complex Debugging**: Troubleshooting across container boundaries
- **Operational Complexity**: More services to monitor and manage
- **Startup Dependencies**: Services must start in correct order
- **Storage Management**: Multiple persistent volumes required

## Alternatives Considered

### Single Container with All Services
**Rejected**: Creates resource conflicts, unrealistic deployment patterns, and doesn't teach proper service separation principles.

### External Shared Services  
**Rejected**: Data isolation concerns and potential conflicts between workshop participants accessing shared database instances.

### Local Development with Docker Compose
**Rejected**: Environment inconsistencies across participant machines and complex setup requirements.

### Serverless Functions for Services
**Rejected**: Doesn't meet educational requirements for understanding persistent service architecture and state management.

## Implementation Notes

### Service Configuration

#### PostgreSQL Sidecar (Optimized based on feasibility study)
```yaml
- name: postgresql
  container:
    image: registry.redhat.io/rhel8/postgresql-13:1
    resources:
      requests:
        memory: "256Mi"  # Optimized for workshop workload
        cpu: "100m"
      limits:
        memory: "512Mi"  # Maintains safety buffer
        cpu: "500m"
    env:
      - name: POSTGRESQL_USER
        value: attendee
      - name: POSTGRESQL_PASSWORD
        value: workshop
      - name: POSTGRESQL_DATABASE
        value: conference
      - name: POSTGRESQL_SHARED_BUFFERS
        value: "64MB"    # Tuned for container environment
      - name: POSTGRESQL_WORK_MEM
        value: "4MB"     # Conservative for low-intensity workload
```

#### Kafka Sidecar (Optimized based on feasibility study)
```yaml
- name: kafka
  container:
    image: registry.redhat.io/amq7/amq-streams-kafka-30-rhel8:2.0.0
    resources:
      requests:
        memory: "512Mi"  # Optimized for workshop workload
        cpu: "200m"
      limits:
        memory: "1Gi"    # Maintains safety buffer
        cpu: "1000m"
    env:
      - name: KAFKA_HEAP_OPTS
        value: "-Xmx256m -Xms256m"  # 50% of memory request
      - name: KAFKA_ZOOKEEPER_CONNECT
        value: localhost:2181
```

### Service Discovery
Services accessible via Kubernetes DNS:
- PostgreSQL: `ddd-workshop-postgresql.ddd-workshop.svc.cluster.local:5432`
- Kafka: `ddd-workshop-kafka.ddd-workshop.svc.cluster.local:9092`

### Startup Orchestration
```yaml
events:
  preStart:
    - "wait-for-postgresql"
    - "wait-for-kafka"
    - "init-maven-cache"
```

### Success Metrics
- Service startup time < 30 seconds
- Zero service connectivity issues during workshops
- Independent service scaling without affecting other components
- Successful data persistence across development sessions

## Related Decisions
- [ADR-0001](adr-0001-inner-loop-development-architecture.md): Inner Loop Development Architecture
- ADR-0003: Inner/Outer Loop Separation Strategy (planned)
- ADR-0008: Service Connectivity Pattern (planned)

## Research Findings Integration

### Technical Feasibility Study Results (2025-08-02)
**Key Finding**: PostgreSQL (512Mi) and Kafka (1Gi) resource allocations are over-provisioned for workshop workloads, presenting significant cost optimization opportunities.

**Optimization Opportunities**:
- **Cost Reduction**: Potential 14Gi memory savings across 20 users through right-sizing
- **Improved Density**: Better cluster utilization through optimized resource requests
- **Maintained Safety**: Limits preserved to handle peak workshop activities

**Implemented Optimizations**:
1. **PostgreSQL**: Reduced memory request from 512Mi to 256Mi (50% reduction)
2. **Kafka**: Reduced memory request from 1Gi to 512Mi (50% reduction)
3. **JVM Tuning**: Kafka heap size set to 50% of memory request to prevent OOMKilled errors
4. **Database Tuning**: PostgreSQL parameters optimized for containerized, low-intensity workload

**Risk Mitigation**: "Request Low, Limit High" strategy maintains safety buffers while optimizing resource utilization.

## References
- Knowledge Graph: Development Infrastructure visualization
- Devfile configuration: Multi-container sidecar implementation
- Kubernetes service discovery documentation
- Workshop requirements: Realistic microservices patterns
- Technical Feasibility Study: `docs/research/reseach-response-2025-08-02.md`
