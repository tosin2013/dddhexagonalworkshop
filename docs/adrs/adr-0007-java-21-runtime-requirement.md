# ADR-0007: Java 21 Runtime Requirement for Workshop Environment

## Status
Accepted

## Context

The DDD Hexagonal Architecture Workshop uses Quarkus as the primary development framework. During the migration to OpenShift Dev Spaces, we discovered that the workshop modules require specific Java and Quarkus versions that impact the container image selection and development environment configuration.

### Current Workshop Requirements
- **Quarkus Version**: 3.23.0 (specified in all module pom.xml files)
- **Maven Compiler Release**: 21 (maven.compiler.release=21)
- **Java Language Features**: Modern Java features available in Java 21

### Container Image Compatibility
The workshop was initially configured with various Java runtime images, but build failures revealed version mismatches:
- `registry.redhat.io/devspaces/udi-rhel8:3.15` - Contains Java 11/17
- `registry.access.redhat.com/ubi8/openjdk-21:1.20` - Runtime image, not development
- `registry.access.redhat.com/ubi9/openjdk-21:1.20` - Development-ready Java 21

### Build Error Analysis
```
ERROR: release version 21 not supported
Fatal error compiling: error: release version 21 not supported
```

This error occurs when the container Java version doesn't match the Maven compiler release target.

## Decision

We will standardize on **Java 21** as the required runtime for the DDD Hexagonal Architecture Workshop, using the Red Hat UBI9 OpenJDK 21 container image.

### Container Image Selection
- **Primary Image**: `registry.access.redhat.com/ubi9/openjdk-21:1.20`
- **Rationale**: Provides Java 21 runtime with development tools
- **Enterprise Support**: Red Hat certified and supported image
- **Security**: Regular security updates and vulnerability scanning

### Development Environment Configuration
```yaml
# devfile.yaml configuration
components:
  - name: tools
    container:
      image: registry.access.redhat.com/ubi9/openjdk-21:1.20
      env:
        - name: JAVA_HOME
          value: "/usr/lib/jvm/java-21-openjdk"
        - name: MAVEN_OPTS
          value: "-Xmx512m"
```

### Maven Configuration Alignment
All workshop modules will maintain:
```xml
<properties>
    <maven.compiler.release>21</maven.compiler.release>
    <quarkus.platform.version>3.23.0</quarkus.platform.version>
</properties>
```

## Consequences

### Positive
- **Build Compatibility**: Eliminates Java version mismatch errors
- **Modern Features**: Access to Java 21 language features and performance improvements
- **Quarkus Compatibility**: Full support for Quarkus 3.23.0 features
- **Enterprise Support**: Red Hat certified image with enterprise support
- **Performance**: Java 21 performance improvements for workshop applications
- **Future-Proof**: Aligns with modern Java development practices

### Negative
- **Image Size**: Java 21 images may be larger than Java 11 alternatives
- **Learning Curve**: Participants unfamiliar with Java 21 features
- **Compatibility**: Older development tools may not fully support Java 21
- **Resource Usage**: Potentially higher memory usage compared to Java 11

### Neutral
- **Migration Path**: Clear upgrade path for existing Java 11/17 environments
- **Documentation**: Updated workshop materials to reflect Java 21 requirements

## Implementation Plan

### Phase 1: Container Image Update
1. Update devfile configurations to use UBI9 OpenJDK 21 image
2. Test container startup and Java version verification
3. Validate Maven wrapper functionality with Java 21

### Phase 2: Build Validation
1. Test compilation of all workshop modules
2. Verify Quarkus development mode functionality
3. Validate hot reload and live coding features

### Phase 3: Workshop Testing
1. End-to-end testing of workshop modules
2. Performance validation under multi-user load
3. Documentation updates for Java 21 requirements

### Phase 4: Deployment
1. Update production devfile configurations
2. Deploy to workshop environments
3. Participant onboarding with Java 21 environment

## Compliance and Security

### Enterprise Requirements
- **Red Hat Certification**: UBI9 images are Red Hat certified
- **Security Scanning**: Regular vulnerability assessments
- **Support Lifecycle**: Aligned with Red Hat support lifecycle
- **Compliance**: Meets enterprise security and compliance requirements

### Version Management
- **LTS Alignment**: Java 21 is an LTS (Long Term Support) release
- **Update Strategy**: Regular image updates following Red Hat release cycle
- **Backward Compatibility**: Maintains compatibility with existing workshop code

## Monitoring and Validation

### Build Success Metrics
- **Compilation Success Rate**: 100% successful builds across all modules
- **Startup Time**: Container startup within acceptable thresholds
- **Memory Usage**: Efficient memory utilization within resource limits

### Performance Indicators
- **Hot Reload Performance**: Quarkus development mode responsiveness
- **Multi-User Scalability**: Performance under concurrent workshop load
- **Resource Efficiency**: CPU and memory usage optimization

## References
- [Java 21 Release Notes](https://openjdk.org/projects/jdk/21/)
- [Quarkus 3.23.0 Documentation](https://quarkus.io/version/3.23/guides/)
- [Red Hat UBI9 OpenJDK Images](https://catalog.redhat.com/software/containers/ubi9/openjdk-21/618bdbf34ae3739687568813)
- ADR-0001: Inner Loop Development Architecture
- ADR-0002: Development Infrastructure Sidecar Pattern

## Author
Tosin Akinsoho <takinosh@redhat.com>

## Date
2025-08-04
