# Step 7: Outbound Adapters for Events

## tl;dr

_If you want to get the application up and running as quickly as possible you can copy/paste the code into the stubbed classes without reading the rest of the material._

Update `AttendeeEventPublisher` to send messages to Kafka.  We are going to use the Microprofile `Channel` and `Emitter` classes to avoid any about Kafka specific details.

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

import dddhexagonalworkshop.conference.attendees.domain.events.AttendeeRegisteredEvent;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

/**
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter, which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on all sides of it, without actually knowing the nature of the things on the other side of the adapters."
 * Alistair Cockburn, Hexagonal Architecture, 2005.
 *
 * Outbound adapter for publishing domain events to external messaging systems.
 *
 * This adapter implements the Hexagonal Architecture pattern by providing
 * a clean abstraction between domain event publishing needs and the specific
 * messaging technology (Kafka in this case).
 *
 * The adapter handles:
 * - Technology-specific event publishing (Kafka via MicroProfile Reactive Messaging)
 * - Error handling and logging
 * - Message routing and serialization
 * - Maintaining loose coupling between domain and infrastructure
 */

@ApplicationScoped
public class AttendeeEventPublisher {

    @Channel("attendees")
    public Emitter<AttendeeRegisteredEvent> attendeesTopic;

    public void publish(AttendeeRegisteredEvent attendeeRegisteredEvent) {
        attendeesTopic.send(attendeeRegisteredEvent);
    }
}
```

[Step 8: Application Services](08-Application-Services.md)

## Learning Objectives
- **Understand** Outbound Adapters as the bridge between domain events and external systems
- **Implement** AttendeeEventPublisher to send domain events to Kafka
- **Apply** Hexagonal Architecture principles to decouple event publishing from business logic
- **Connect** domain events to external messaging systems while maintaining clean boundaries

## What You'll Build
An `AttendeeEventPublisher` adapter that publishes `AttendeeRegisteredEvent` domain events to Kafka, enabling other bounded contexts and systems to react to attendee registrations.

## Why Outbound Adapters Are Critical

Outbound Adapters solve the fundamental problem of **how domain logic communicates with external systems** without being polluted by technical concerns:

**The Technology Coupling Problem**: Without adapters, domain logic gets tied to specific technologies:

❌ Domain service coupled to Kafka implementation

```java
@ApplicationScoped
public class AttendeeService {
    @Inject @Channel("attendees") Emitter<AttendeeRegisteredEvent> kafkaEmitter;
    
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand command) {
        AttendeeRegistrationResult result = Attendee.registerAttendee(command.email());
        attendeeRepository.persist(result.attendee());
        
        // Domain service knows about Kafka - tight coupling!
        kafkaEmitter.send(result.attendeeRegisteredEvent());
        
        return new AttendeeDTO(result.attendee().getEmail());
    }
}
```

**The Adapter Solution**: Adapters abstract external technology behind domain interfaces:

✅ Domain service uses clean abstraction

```java
@ApplicationScoped
public class AttendeeService {
    @Inject AttendeeEventPublisher eventPublisher;  // Domain interface
    
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand command) {
        AttendeeRegistrationResult result = Attendee.registerAttendee(command.email());
        attendeeRepository.persist(result.attendee());
        
        // Clean domain operation - technology agnostic
        eventPublisher.publish(result.attendeeRegisteredEvent());
        
        return new AttendeeDTO(result.attendee().getEmail());
    }
}
```

## Hexagonal Architecture: Ports and Adapters Deep Dive

Understanding the relationship between Ports and Adapters is crucial for proper implementation:

### Ports vs Adapters: Core Concepts

| Aspect | Port | Adapter |
|--------|------|---------|
| **Definition** | Interface/Contract | Implementation |
| **Location** | Domain layer | Infrastructure layer |
| **Purpose** | Define what operations are needed | Implement how operations work |
| **Dependency Direction** | Domain defines ports | Adapters depend on ports |
| **Technology** | Technology agnostic | Technology specific |

### Inbound vs Outbound Adapters

| Aspect | Inbound Adapter | Outbound Adapter |
|--------|-----------------|-------------------|
| **Purpose** | External world → Domain | Domain → External world |
| **Examples** | REST endpoints, CLI, GUI | Database, messaging, email |
| **Data Flow** | Receives requests/data | Sends commands/events |
| **Initiator** | External system | Domain logic |
| **Port Type** | Primary/Driving Port | Secondary/Driven Port |

**Inbound Adapter Example** (External → Domain):
```java
// Port (domain interface)
public interface AttendeeRegistrationUseCase {
    AttendeeDTO registerAttendee(RegisterAttendeeCommand command);
}

// Adapter (infrastructure implementation)
@Path("/attendees")
public class AttendeeEndpoint {
    @Inject AttendeeRegistrationUseCase useCase;  // Uses domain port
    
    @POST
    public Response register(RegisterAttendeeCommand command) {
        AttendeeDTO result = useCase.registerAttendee(command);  // Calls into domain
        return Response.ok(result).build();
    }
}
```

**Outbound Adapter Example** (Domain → External):
```java
// Port (domain interface)
public interface EventPublisher {
    void publish(DomainEvent event);
}

// Adapter (infrastructure implementation)
@ApplicationScoped
public class KafkaEventPublisher implements EventPublisher {
    @Channel("events") Emitter<DomainEvent> kafkaEmitter;
    
    public void publish(DomainEvent event) {
        kafkaEmitter.send(event);  // Implements domain requirement
    }
}
```

### Event Publishing Patterns Comparison

| Pattern | Responsibility | Coupling | Flexibility | Complexity |
|---------|----------------|----------|-------------|------------|
| **Direct Messaging** | Service publishes directly | High (tied to message broker) | Low | Low |
| **Event Publisher Adapter** | Adapter handles publishing | Low (abstracted interface) | High | Medium |
| **Event Store + Projections** | Event store projects events | Very low (async) | Very high | High |
| **Outbox Pattern** | Database + background processor | Low (transactional) | High | High |

**Direct Messaging** (Tight Coupling):

❌ Service directly coupled to messaging technology

```java
public class AttendeeService {
    @Channel("attendees") Emitter<AttendeeRegisteredEvent> emitter;
    
    public void registerAttendee(RegisterAttendeeCommand cmd) {
        // Business logic
        emitter.send(event);  // Direct technology dependency
    }
}
```

**Event Publisher Adapter** (Loose Coupling):

✅ Service uses domain abstraction

```java
public class AttendeeService {
    @Inject EventPublisher publisher;  // Domain interface
    
    public void registerAttendee(RegisterAttendeeCommand cmd) {
        // Business logic
        publisher.publish(event);  // Technology agnostic
    }
}
```

**Outbox Pattern** (Transactional Safety):

✅ Transactionally safe event publishing

```java
public class TransactionalEventPublisher implements EventPublisher {
    public void publish(DomainEvent event) {
        // Store event in database within same transaction
        outboxRepository.store(new OutboxEvent(event));
        // Background processor publishes from outbox
    }
}
```

## Implementation

Event publishers are adapters that propagate domain events to external messaging systems, enabling other bounded contexts to react to business changes without direct coupling.

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

import dddhexagonalworkshop.conference.attendees.domain.events.AttendeeRegisteredEvent;
import jakarta.enterprise.context.ApplicationScoped;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;

/**
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter, which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on all sides of it, without actually knowing the nature of the things on the other side of the adapters."
 * Alistair Cockburn, Hexagonal Architecture, 2005.
 *
 * Outbound adapter for publishing domain events to external messaging systems.
 *
 * This adapter implements the Hexagonal Architecture pattern by providing
 * a clean abstraction between domain event publishing needs and the specific
 * messaging technology (Kafka in this case).
 *
 * The adapter handles:
 * - Technology-specific event publishing (Kafka via MicroProfile Reactive Messaging)
 * - Error handling and logging
 * - Message routing and serialization
 * - Maintaining loose coupling between domain and infrastructure
 */

@ApplicationScoped
public class AttendeeEventPublisher {

    @Channel("attendees")
    public Emitter<AttendeeRegisteredEvent> attendeesTopic;

    public void publish(AttendeeRegisteredEvent attendeeRegisteredEvent) {
        attendeesTopic.send(attendeeRegisteredEvent);
    }
}
```

### Key Design Decisions

**Technology Abstraction**: The adapter uses MicroProfile Reactive Messaging, which abstracts Kafka details while providing a standard API.

### Connection to Other Components

This adapter will be:
1. **Called** by the `AttendeeService` to publish domain events
2. **Receive** `AttendeeRegisteredEvent` objects from the domain layer
3. **Convert** domain events to message format (JSON via Quarkus serialization)
4. **Send** events to Kafka for consumption by other bounded contexts

## Common Questions

**Q: Should adapters contain business logic?**
A: No, adapters should only handle technical concerns like serialization, routing, and error handling. Business logic belongs in domain aggregates and services.

**Q: How do I handle event publishing failures?**
A: Consider patterns like retry mechanisms, dead letter queues, or the outbox pattern for guaranteed delivery. The choice depends on your consistency requirements.

**Q: Should I publish events synchronously or asynchronously?**
A: It depends on your requirements. Synchronous publishing provides immediate feedback but can slow down business operations. Asynchronous publishing improves performance but requires careful error handling.

**Q: How do I ensure event ordering?**
A: Use message keys for partitioning in Kafka, or implement ordering at the application level if cross-partition ordering is required.

**Q: Should each event type have its own adapter?**
A: Not necessarily. You can have one adapter per messaging technology (e.g., KafkaEventPublisher) that handles multiple event types, or separate adapters if they have very different routing/transformation requirements.

## Next Steps

In the next step, we'll create the `AttendeeService` domain service that orchestrates the entire attendee registration workflow. The service will coordinate between the aggregate, repository, and event publisher, demonstrating how all the components work together in a clean, hexagonal architecture: [Step 8: Application Services](08-Application-Services.md)

