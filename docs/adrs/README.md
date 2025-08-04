# Architectural Decision Records (ADRs)

This directory contains the Architectural Decision Records for the DDD Hexagonal Architecture Workshop project.

## ADR Index

| ADR | Title | Status | Date | Impact | Research Updated |
|-----|-------|--------|------|--------|------------------|
| [ADR-0001](adr-0001-inner-loop-development-architecture.md) | Inner Loop Development Architecture with OpenShift Dev Spaces | Accepted | 2025-08-01 | High | ✅ 2025-08-02 |
| [ADR-0002](adr-0002-development-infrastructure-sidecar-pattern.md) | Development Infrastructure Sidecar Pattern | Accepted | 2025-08-01 | High | ✅ 2025-08-02 |
| [ADR-0003](adr-0003-inner-outer-loop-separation-strategy.md) | Inner/Outer Loop Separation Strategy | Deprecated | 2025-08-01 | High | ✅ 2025-08-02 |
| [ADR-0004](adr-0004-environment-progression-strategy.md) | Environment Progression Strategy | Deprecated | 2025-08-01 | Medium | - |
| [ADR-0007](adr-0007-java-21-runtime-requirement.md) | Java 21 Runtime Requirement for Workshop Environment | Accepted | 2025-08-04 | High | - |

## ADR Status Definitions

- **Proposed**: Decision is under consideration
- **Accepted**: Decision has been approved and is being implemented
- **Deprecated**: Decision is no longer relevant but kept for historical context
- **Superseded**: Decision has been replaced by a newer ADR

## Planned ADRs

Based on the project analysis, the following additional ADRs are planned:

### High Priority (Completed ✅)
- ✅ **ADR-0001**: Inner Loop Development Architecture with OpenShift Dev Spaces
- ✅ **ADR-0002**: Development Infrastructure Sidecar Pattern
- ✅ **ADR-0007**: Java 21 Runtime Requirement for Workshop Environment

### Deprecated (No Longer Applicable)
- ❌ **ADR-0003**: Inner/Outer Loop Separation Strategy (Workshop focuses on inner loop only)
- ❌ **ADR-0004**: Environment Progression Strategy (Single environment approach)
- ❌ **ADR-0005**: CI/CD Pipeline Architecture (Removed - not needed for workshop)

### Medium Priority (Planned)
- **ADR-0006**: Feedback Loop Architecture
- **ADR-0007**: Developer Experience Optimization
- **ADR-0008**: Service Connectivity Pattern
- **ADR-0009**: Multi-Environment Monitoring Strategy

### Educational Focus
- **ADR-0010**: Workshop Learning Flow Architecture
- **ADR-0011**: Domain-Driven Design Implementation Strategy
- **ADR-0012**: Hexagonal Architecture Pattern Implementation

## ADR Template

We use the NYGARD template format for consistency:

```markdown
# ADR-XXXX: [Title]

## Status
[Proposed | Accepted | Deprecated | Superseded]

## Context
[Describe the context and problem statement]

## Decision
[Describe the architectural decision]

## Consequences
[Describe the positive and negative consequences]

## Alternatives Considered
[List alternatives that were considered]

## Implementation Notes
[Technical implementation details]

## Related Decisions
[Links to related ADRs]

## References
[Supporting documentation and resources]
```

## Contributing

When creating new ADRs:

1. Use the next sequential number (ADR-XXXX)
2. Follow the template format above
3. Update this README.md index
4. Link related ADRs bidirectionally
5. Include evidence from code, configuration, or documentation

## Review Process

1. **Propose**: Create ADR with "Proposed" status
2. **Review**: Team reviews and provides feedback
3. **Accept**: ADR status changed to "Accepted" after approval
4. **Implement**: Technical implementation follows ADR guidance
5. **Update**: ADR updated if implementation differs from original decision

## Knowledge Graph Integration

ADRs should reference and align with the project's knowledge graph (`knowledge-graph.mmd`) which visualizes:
- Developer workflow patterns
- Inner Loop (OpenShift Dev Spaces) architecture
- Outer Loop (CI/CD) architecture
- Environment progression and feedback loops

This ensures architectural decisions are grounded in actual workflow patterns and visual documentation.

## Research Integration

ADRs are continuously updated based on research findings and feasibility studies:

### Research Integration Process
1. **Research Conducted**: Technical feasibility studies and architectural analysis
2. **Findings Analysis**: Key insights extracted and impact assessed
3. **ADR Updates**: Relevant ADRs updated with research findings and revised criteria
4. **Validation**: Updated decisions validated against research evidence

### Recent Research Integration (2025-08-02)
**Source**: Technical Feasibility Study (`docs/research/reseach-response-2025-08-02.md`)

**Key Updates Applied**:
- **ADR-0001**: Revised live reload success criteria based on Quarkus concurrent performance analysis
- **ADR-0002**: Optimized resource allocations with "Request Low, Limit High" strategy
- **ADR-0003**: Added standardized devfile requirements for integration reliability
- **ADR-0005**: Implemented tiered security scanning strategy for pipeline optimization

**Impact**: Enhanced feasibility and implementation guidance based on empirical analysis
