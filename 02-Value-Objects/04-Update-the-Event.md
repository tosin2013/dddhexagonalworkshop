# Step 4: Update the AttendeeRegisteredEvent

## tl;dr

```java
package dddhexagonalworkshop.conference.attendees.domain.events;

public record AttendeeRegisteredEvent(String email, String fullName) {
}
```

## What We Are Building

In this step, we'll update the `AttendeeRegisteredEvent` to include the attendee's full name. This demonstrates thoughtful event design - including relevant information while avoiding over-coupling between bounded contexts.

## Learning Objectives

- Understanding Domain Events

## Why Domain Events Matter

Domain Events are:

- Notifications that something important has happened in the domain
- Used to integrate between bounded contexts
- Should contain only the information needed by subscribers
- Immutable once created

The important thing to note here is that while we have updated the Domain Event with the Attendee's name, we have _not_ added the address.  We have decided not to share all of the attendees information with other Bounded Contexts.  If another Bounded Context needs the Attendee's address, for example, if something needs to be mailed to an individual attendee, we can implement a method that allows other parts of the system to query for the information. 

## Implementation

Update the `AttendeeRegisteredEvent` to include the full name:

```java
package dddhexagonalworkshop.conference.attendees.domain.events;

public record AttendeeRegisteredEvent(String email, String fullName) {
}
```

## Key Design Decisions

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

Continue to [Step 5: Update the Persistence Layer](05-Update-Persistence.md)
