# Workshop Container Dependencies Analysis

## Overview

This document analyzes the PostgreSQL and Kafka container requirements across all three workshop modules in the DDD Hexagonal Architecture Workshop. Understanding these dependencies is crucial for proper devfile configuration and workshop environment setup.

## Executive Summary

| Module | PostgreSQL Required | Kafka Required | Standalone Exercises | Full Integration |
|--------|-------------------|----------------|---------------------|------------------|
| **Module 01** | Step 6+ | Step 7+ | Steps 1-5 | Steps 6-10 |
| **Module 02** | Step 5+ | Step 7+ | Steps 1-4 | Steps 5-7 |
| **Module 03** | All Steps | Step 3+ | Steps 1-2 | Steps 3-5 |

## Module 01: End-to-End DDD

### Container Dependencies
- **PostgreSQL**: Required from Step 6 (Repositories) onwards
- **Kafka**: Required from Step 7 (Outbound Adapters) onwards
- **Both**: Required for Steps 8-10 (complete integration)

### Exercise Breakdown

#### **Steps 1-5: No External Dependencies** ✅
- **01-Events.md**: Domain event modeling (in-memory)
- **02-Commands.md**: Command pattern implementation (in-memory)
- **03-Combining-Return-Values.md**: Result pattern (in-memory)
- **04-Aggregates.md**: Aggregate root design (in-memory)
- **05-Entities.md**: Entity modeling (in-memory)

**Can Run With**: Java 21 container only
**Focus**: Pure domain modeling and business logic

#### **Step 6: PostgreSQL Required** 🔵
- **06-Repositories.md**: Repository pattern with Hibernate ORM Panache
- **Database Operations**: Persist/retrieve Attendee aggregates
- **Dependencies Used**: `quarkus-hibernate-orm-panache`, `quarkus-jdbc-postgresql`
- **Will Fail Without**: PostgreSQL container

#### **Step 7: Kafka Required** 🟡
- **07-Outbound-Adapters.md**: Event publishing with MicroProfile Reactive Messaging
- **Messaging Operations**: Send AttendeeRegisteredEvent to Kafka
- **Dependencies Used**: `quarkus-messaging-kafka`
- **Will Fail Without**: Kafka container

#### **Steps 8-10: Both Required** 🔴
- **08-Application-Services.md**: Service layer orchestration
- **09-Data-Transfer-Objects.md**: API contract definitions
- **10-Inbound-Adapters.md**: REST API endpoints
- **Full Integration**: HTTP → Domain → Database → Events
- **Will Fail Without**: Both PostgreSQL and Kafka containers

## Module 02: Value Objects

### Container Dependencies
- **PostgreSQL**: Required from Step 5 (Update Persistence) onwards
- **Kafka**: Required from Step 7 (Update the Service) onwards
- **Both**: Required for complete value object integration

### Exercise Breakdown

#### **Steps 1-4: No External Dependencies** ✅
- **01-Value-Objects.md**: Value object concepts and implementation
- **02-Update-the-Command.md**: Command enhancement with value objects
- **03-Update-the-Aggregate.md**: Aggregate modification for value objects
- **04-Update-the-Event.md**: Event enhancement with value objects

**Can Run With**: Java 21 container only
**Focus**: Value object modeling and domain logic

#### **Step 5: PostgreSQL Required** 🔵
- **05-Update-Persistence.md**: Database schema changes for value objects
- **Database Operations**: Create AddressEntity, update AttendeeEntity mapping
- **Object-Relational Mapping**: Handle impedance mismatch between domain and persistence
- **Dependencies Used**: `quarkus-hibernate-orm-panache`, `quarkus-jdbc-postgresql`
- **Will Fail Without**: PostgreSQL container

#### **Step 6: PostgreSQL Required** 🔵
- **06-Update-the-DTO.md**: Data Transfer Object updates
- **API Contract**: Expose value objects through REST API
- **Dependencies Used**: Database access for DTO population
- **Will Fail Without**: PostgreSQL container

#### **Step 7: Both Required** 🔴
- **07-Update-the-Service.md**: Service layer integration
- **Full Integration**: Complete value object flow with persistence and events
- **Dependencies Used**: Both database and messaging
- **Will Fail Without**: Both PostgreSQL and Kafka containers

## Module 03: Anticorruption Layer

### Container Dependencies
- **PostgreSQL**: Required for all steps (builds on Module 01/02)
- **Kafka**: Required from Step 3 (Inbound Adapter) onwards
- **Both**: Required for most exercises due to integration nature

### Exercise Breakdown

#### **Steps 1-2: Domain Logic Only** ✅
- **01-The-External-System.md**: External system modeling
- **02-Implement-a-Translator.md**: Translation logic implementation

**Can Run With**: Java 21 container only
**Focus**: Translation patterns and domain logic
**Note**: These steps build translation logic but don't persist or publish

#### **Step 3: Both Required** 🔴
- **03-Inbound-Adapter.md**: REST endpoint for external system integration
- **Integration Flow**: External data → Translation → Domain → Persistence → Events
- **Dependencies Used**: Full stack integration
- **Will Fail Without**: Both PostgreSQL and Kafka containers

#### **Steps 4-5: Both Required** 🔴
- **04-Value-Objects.md**: Value object integration in anticorruption layer
- **05-Update-the-Command.md**: Command enhancement for external integration
- **Full Integration**: Complete anticorruption layer with all dependencies
- **Will Fail Without**: Both PostgreSQL and Kafka containers

## Technical Implementation Details

### Maven Dependencies Analysis

All three modules include identical dependencies:
```xml
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-hibernate-orm-panache</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-messaging-kafka</artifactId>
</dependency>
<dependency>
    <groupId>io.quarkus</groupId>
    <artifactId>quarkus-jdbc-postgresql</artifactId>
</dependency>
```

### Application Properties Configuration

All modules configure both PostgreSQL and Kafka:
```properties
# PostgreSQL Configuration
quarkus.datasource.db-kind=postgresql
quarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5432/conference

# Kafka Configuration
kafka.bootstrap.servers=localhost:9092
mp.messaging.connector.smallrye-kafka.bootstrap.servers=localhost:9092
```

## Devfile Configuration Recommendations

### Option 1: Progressive Development
```yaml
# For early exercises (Steps 1-5 Module 01, Steps 1-4 Module 02, Steps 1-2 Module 03)
devfile-java21.yaml  # Java 21 container only

# For database exercises (Step 6+ Module 01, Step 5+ Module 02, Step 3+ Module 03)
devfile-with-postgresql.yaml  # Java 21 + PostgreSQL sidecar

# For full integration (Step 7+ Module 01, Step 7+ Module 02, Step 3+ Module 03)
devfile-complete.yaml  # Java 21 + PostgreSQL + Kafka sidecars
```

### Option 2: Complete Environment
```yaml
# Single devfile with all services for complete workshop experience
devfile-complete.yaml  # Java 21 + PostgreSQL + Kafka sidecars
```

## Workshop Delivery Strategies

### Strategy 1: Modular Approach
- **Phase 1**: Domain modeling exercises (no external dependencies)
- **Phase 2**: Persistence exercises (add PostgreSQL)
- **Phase 3**: Event-driven exercises (add Kafka)
- **Phase 4**: Full integration exercises (both services)

### Strategy 2: Complete Environment
- **Single Setup**: All services available from start
- **Benefit**: No environment switching during workshop
- **Drawback**: Higher resource usage for early exercises

## Resource Requirements

### Minimal Configuration (Java 21 only)
- **Memory**: 768Mi per workspace
- **CPU**: 500m per workspace
- **Suitable For**: Steps 1-5 (Module 01), Steps 1-4 (Module 02), Steps 1-2 (Module 03)

### Complete Configuration (Java 21 + PostgreSQL + Kafka)
- **Memory**: 2.3Gi per workspace (768Mi + 384Mi + 768Mi + overhead)
- **CPU**: 1000m per workspace (500m + 200m + 300m)
- **Suitable For**: All workshop exercises

## Troubleshooting Guide

### Common Issues Without Required Containers

#### PostgreSQL Missing
```
ERROR: Connection to localhost:5432 refused
ERROR: Unable to create initial connections of pool
```

#### Kafka Missing
```
ERROR: Connection to node -1 (localhost:9092) could not be established
ERROR: Failed to send message to topic 'workshop-events'
```

### Verification Commands
```bash
# Check PostgreSQL connectivity
nc -zv localhost 5432

# Check Kafka connectivity
nc -zv localhost 9092

# Check application health
curl http://localhost:8080/q/health
```

## Conclusion

Understanding container dependencies is crucial for successful workshop delivery. The analysis shows a clear progression from pure domain modeling (no external dependencies) to full integration scenarios (requiring both PostgreSQL and Kafka). Workshop facilitators should choose the appropriate devfile configuration based on their delivery strategy and resource constraints.

## Author
Tosin Akinsoho <takinosh@redhat.com>

## Date
2025-08-04
