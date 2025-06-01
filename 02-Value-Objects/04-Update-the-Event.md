# Step 4: Update the AttendeeRegisteredEvent

## Overview

In this step, we'll update the `AttendeeRegisteredEvent` to include the attendee's full name. This demonstrates thoughtful event design - including relevant information while avoiding over-coupling between bounded contexts.

## Understanding Domain Events

Domain Events are:

- Notifications that something important has happened in the domain
- Used to integrate between bounded contexts
- Should contain only the information needed by subscribers
- Immutable once created

## Implementation

Update the `AttendeeRegisteredEvent` to include the full name:

```java
package dddhexagonalworkshop.conference.attendees.domain.events;

public record AttendeeRegisteredEvent(String email, String fullName) {
}
```

## Design Decisions

### What We Include

- **Email**: Primary identifier for the attendee
- **Full Name**: Useful for notifications and displays in other contexts

### What We Don't Include

- **Address**: Not included because it's not necessary for most event subscribers
- **Individual Name Fields**: We provide the computed full name instead

## Strategic Design Considerations

**Bounded Context Integration**: If, in the future, a different Bounded Context needs an attendee's address, we can work with the team that owns that Bounded Context to implement a method for them to query our microservice for the attendee's address.

This approach:

- Keeps events lean and focused
- Reduces coupling between bounded contexts
- Allows for future evolution through explicit integration patterns

## Event Design Principles

1. **Minimal Information**: Include only what subscribers actually need
2. **Stable Interface**: Changes to internal models don't break event consumers
3. **Business-Focused**: Events represent business occurrences, not technical changes
4. **Immutable**: Using Java records ensures events can't be modified after creation

## Benefits

- **Loose Coupling**: Other bounded contexts don't depend on our internal Address structure
- **Evolution**: Internal changes to address handling don't break event consumers
- **Performance**: Smaller events reduce serialization overhead
- **Clarity**: Clear what information is available to event subscribers

## Next Step

Continue to [Step 5: Update the Persistence Layer](step5-update-persistence.md)
