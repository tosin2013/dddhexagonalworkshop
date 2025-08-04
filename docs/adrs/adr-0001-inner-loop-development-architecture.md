# ADR-0001: Inner Loop Development Architecture with OpenShift Dev Spaces

## Status
Proposed

## Context
The DDD Hexagonal Architecture Workshop requires a fast, iterative development environment that supports live reload, hot deployment, and integrated development tools. Workshop participants need immediate feedback loops to effectively learn Domain-Driven Design and Hexagonal Architecture patterns. 

The development environment must support multiple users simultaneously while maintaining isolation and performance. Traditional local development setups create inconsistencies across different participant environments and require complex setup procedures that detract from learning objectives.

Key requirements:
- Fast development cycles with immediate feedback
- Consistent environment across all workshop participants  
- Support for Domain-Driven Design and Hexagonal Architecture patterns
- Multi-user workshop delivery capability
- Enterprise compliance and security requirements

## Decision
Implement Inner Loop development architecture using OpenShift Dev Spaces with Quarkus development mode, integrated IDE support, and containerized development infrastructure.

The architecture includes:

1. **Quarkus Dev Mode** with live reload and hot deploy capabilities
2. **Integrated Development Environment** with VS Code/IntelliJ support  
3. **Development Tools Integration** including Maven and Git
4. **Sidecar Pattern** with dedicated PostgreSQL and Kafka containers for development data and event testing
5. **Service Connectivity** using Kubernetes DNS for reliable inter-service communication

This decision aligns with the knowledge graph architecture showing:
- Inner Loop workflow with integrated development tools
- Containerized development infrastructure (PostgreSQL, Kafka)
- Clear separation between development and deployment cycles

## Consequences

### Positive Consequences
- **Enhanced Developer Productivity**: Immediate feedback loops through live reload
- **Consistent Environment**: All participants work in identical development environments
- **Reduced Context Switching**: Integrated tools minimize workflow interruptions
- **Realistic Development Environment**: Mirrors production patterns and constraints
- **Simplified Onboarding**: Participants can start coding immediately without complex setup
- **Better Resource Utilization**: Container isolation provides efficient resource management
- **Educational Effectiveness**: Technical architecture reinforces learning objectives

### Negative Consequences  
- **Increased Setup Complexity**: Initial environment configuration requires platform expertise
- **Platform Dependency**: Tight coupling to OpenShift Dev Spaces platform
- **Learning Curve**: Participants unfamiliar with cloud-native development need additional support
- **Network Latency**: Remote development may introduce latency compared to local development
- **Resource Constraints**: Shared cluster environments may limit individual resource allocation
- **Operational Overhead**: Requires ongoing platform maintenance and monitoring

## Alternatives Considered

### Local Development with Docker Compose
**Rejected**: Creates environment inconsistencies across different participant machines and requires complex setup procedures that detract from learning objectives.

### GitHub Codespaces with Docker-in-Docker  
**Rejected**: Does not meet enterprise compliance requirements and has resource limitations for multi-service development environments.

### Traditional IDE Setup with Local Services
**Rejected**: High setup complexity, maintenance overhead, and inconsistent environments across participants.

### Cloud-based IDEs without Container Integration
**Rejected**: Lacks realistic development environment that mirrors production deployment patterns.

## Implementation Notes

### Technical Requirements
- OpenShift Dev Spaces operator installed at cluster level
- Devfile v2.2+ configuration with sidecar pattern
- Red Hat UBI9 OpenJDK 21 base images (registry.access.redhat.com/ubi9/openjdk-21:1.20)
- Java 21 runtime required for Quarkus 3.23.0 compatibility
- Kubernetes service discovery for inter-service communication

### Configuration Details
- Quarkus development container: 1Gi memory limit, 500m CPU limit, Java 21 runtime
- Quarkus platform version: 3.23.0 (requires Java 21)
- Maven compiler release: 21 (maven.compiler.release=21)
- PostgreSQL sidecar: Development data persistence
- Kafka sidecar: Event streaming and messaging testing
- Maven repository caching for improved startup performance

### Success Metrics
- Workshop participant onboarding time < 10 minutes
- Development environment startup time < 5 minutes
- Live reload response time: 95th percentile < 5 seconds under 20+ concurrent users (Updated based on feasibility study)
- Zero environment-related support tickets during workshops
- Control plane stability: etcd write latency < 100ms under load

## Related Decisions
- ADR-0002: Development Infrastructure Sidecar Pattern (planned)
- ADR-0003: Inner/Outer Loop Separation Strategy (planned)
- Migration from GitHub Codespaces documented in migration guide

## Research Findings Integration

### Technical Feasibility Study Results (2025-08-02)
**Key Finding**: OpenShift Dev Spaces can support 20+ concurrent users, but the original <3 second live reload target is at high risk due to Quarkus dev mode design prioritizing single-user iteration over concurrent performance.

**Critical Risks Identified**:
- **R-01 (High Impact)**: Concurrent live reloads may cause platform instability or exceed response time thresholds
- **R-02 (High Impact)**: etcd datastore contention under concurrent workspace load leading to cluster-wide API slowdowns

**Mitigation Strategies Implemented**:
1. **Revised Success Criteria**: Changed from static <3 second target to 95th percentile <5 seconds under load
2. **Control Plane Monitoring**: Added etcd write latency monitoring requirement
3. **Platform Tuning**: Recommend low-latency profiles for worker nodes hosting Dev Spaces workspaces
4. **Staggered Operations**: Manage participant workflow to avoid simultaneous intensive operations

## References
- Knowledge Graph: Inner Loop architecture visualization
- Devfile configuration: `devfile.yaml`
- OpenShift Dev Spaces documentation
- Workshop requirements: Educational effectiveness and enterprise compliance
- Technical Feasibility Study: `docs/research/reseach-response-2025-08-02.md`
