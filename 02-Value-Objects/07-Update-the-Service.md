# Step 7: Update the AttendeeService

## tl;dr

```java
package dddhexagonalworkshop.conference.attendees.domain.services;

import dddhexagonalworkshop.conference.attendees.domain.aggregates.Attendee;
import dddhexagonalworkshop.conference.attendees.infrastructure.AttendeeDTO;
import dddhexagonalworkshop.conference.attendees.infrastructure.AttendeeEventPublisher;
import dddhexagonalworkshop.conference.attendees.persistence.AttendeeRepository;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

@ApplicationScoped
public class AttendeeService {

    @Inject
    AttendeeRepository attendeeRepository;

    @Inject
    AttendeeEventPublisher attendeeEventPublisher;

    @Transactional
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand command) {
        // Execute domain logic to register the attendee
        AttendeeRegistrationResult result = Attendee.registerAttendee(
                command.email(),
                command.firstName(),
                command.lastName(),
                command.address()
        );

        // Persist the attendee within a transaction
        QuarkusTransaction.requiringNew().run(() -> {
            attendeeRepository.persist(result.attendee());
        });

        // Notify the system that a new attendee has been registered
        attendeeEventPublisher.publish(result.attendeeRegisteredEvent());

        // Return the DTO for the API response
        return new AttendeeDTO(
                result.attendee().getEmail(),
                result.attendee().getFullName()
        );
    }
}
```

## Overview

In this final step, we'll update the `AttendeeService` to handle the new fields and coordinate the entire registration workflow. This demonstrates how application services orchestrate domain operations, persistence, and external integrations.

## Understanding Application Services

Application Services:

- **Orchestrate** business workflows
- **Coordinate** between different domain objects
- **Manage** transactions and persistence
- **Translate** between external interfaces and domain models
- **Handle** cross-cutting concerns like events and notifications

## Implementation

Update the `AttendeeService` to handle the enhanced registration workflow:

```java
package dddhexagonalworkshop.conference.attendees.domain.services;

import dddhexagonalworkshop.conference.attendees.domain.aggregates.Attendee;
import dddhexagonalworkshop.conference.attendees.infrastructure.AttendeeDTO;
import dddhexagonalworkshop.conference.attendees.infrastructure.AttendeeEventPublisher;
import dddhexagonalworkshop.conference.attendees.persistence.AttendeeRepository;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;

@ApplicationScoped
public class AttendeeService {

    @Inject
    AttendeeRepository attendeeRepository;

    @Inject
    AttendeeEventPublisher attendeeEventPublisher;

    @Transactional
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand command) {
        // Execute domain logic to register the attendee
        AttendeeRegistrationResult result = Attendee.registerAttendee(
                command.email(),
                command.firstName(),
                command.lastName(),
                command.address()
        );

        // Persist the attendee within a transaction
        QuarkusTransaction.requiringNew().run(() -> {
            attendeeRepository.persist(result.attendee());
        });

        // Notify the system that a new attendee has been registered
        attendeeEventPublisher.publish(result.attendeeRegisteredEvent());

        // Return the DTO for the API response
        return new AttendeeDTO(
                result.attendee().getEmail(),
                result.attendee().getFullName()
        );
    }
}
```

## Key Components of the Workflow

### 1. Domain Logic Execution

```java
AttendeeRegistrationResult result = Attendee.registerAttendee(
    command.email(),
    command.firstName(),
    command.lastName(),
    command.address()
);
```

- Delegates business logic to the domain model
- Receives both the created aggregate and the domain event

### 2. Persistence Management

```java
QuarkusTransaction.requiringNew().run(() -> {
    attendeeRepository.persist(result.attendee());
});
```

- Uses Quarkus transaction management
- Ensures data consistency
- Separates persistence concerns from domain logic

### 3. Event Publishing

```java
attendeeEventPublisher.publish(result.attendeeRegisteredEvent());
```

- Notifies other parts of the system
- Enables event-driven architecture
- Maintains loose coupling between bounded contexts

### 4. Response Transformation

```java
return new AttendeeDTO(
    result.attendee().getEmail(),
    result.attendee().getFullName()
);
```

- Converts domain objects to DTOs
- Provides stable API interface
- Controls information exposure

## Transaction Management

The service uses two transaction approaches:

- **@Transactional**: For the overall method scope
- **QuarkusTransaction.requiringNew()**: For specific persistence operations

This ensures:

- **Atomicity**: All operations succeed or fail together
- **Consistency**: Database remains in valid state
- **Isolation**: Concurrent operations don't interfere
- **Durability**: Committed changes are permanent

## Error Handling Considerations

In a production system, you would add:

- Input validation
- Business rule validation (duplicate email checking)
- Exception handling and logging
- Retry mechanisms for external systems

## Benefits of This Design

1. **Separation of Concerns**: Each layer has a single responsibility
2. **Testability**: Easy to mock dependencies and test in isolation
3. **Flexibility**: Can easily change persistence or event mechanisms
4. **Consistency**: Transaction management ensures data
