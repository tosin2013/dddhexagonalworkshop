# Step 3: Update the Attendee Aggregate

## tl;dr

Update the `Attendee` aggregate model with the enhanced fields and behavior:

```java
package dddhexagonalworkshop.conference.attendees.domain.aggregates;

import dddhexagonalworkshop.conference.attendees.domain.events.AttendeeRegisteredEvent;
import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeRegistrationResult;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

public class Attendee {

    private String email;
    private String firstName;
    private String lastName;
    private Address address;

    public Attendee(String email, String firstName, String lastName, Address address) {
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.address = address;
    }

    public static AttendeeRegistrationResult registerAttendee(String email, String firstName, String lastName, Address address) {
        // Create the attendee
        Attendee attendee = new Attendee(email, firstName, lastName, address);

        // Here you would typically perform some business logic, like checking if the attendee already exists
        // and then create an event to publish.
        AttendeeRegisteredEvent event = new AttendeeRegisteredEvent(email, attendee.getFullName());
        return new AttendeeRegistrationResult(attendee, event);
    }

    public String getEmail() {
        return email;
    }

    public String getFullName() {
        return firstName + " " + lastName;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public Address getAddress() {
        return address;
    }
}
```


## Overview

In this step, we'll update the `Attendee` aggregate model to include the new address field and first and last name fields. This demonstrates how to evolve domain aggregates while maintaining business logic encapsulation.

## Learning Objectives

- Understand the differences between Value Objects, Aggregates, and Entities
- Understand what behavior can go in a Value Object

## Why Value Objects Matter

Aggregates are:

- Clusters of domain objects treated as a single unit
- Have a root entity that controls access to the aggregate
- Maintain consistency boundaries
- Encapsulate business logic and invariants

Entities represent something with continuity and identity.

Value Objects describe the state of something else.

## What We Are Building

We are implementing a Value Object for Address.  

## Implementation

Update the `Attendee` aggregate model with the enhanced fields and behavior:

```java
package dddhexagonalworkshop.conference.attendees.domain.aggregates;

import dddhexagonalworkshop.conference.attendees.domain.events.AttendeeRegisteredEvent;
import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeRegistrationResult;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

public class Attendee {

    private String email;
    private String firstName;
    private String lastName;
    private Address address;

    public Attendee(String email, String firstName, String lastName, Address address) {
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.address = address;
    }

    public static AttendeeRegistrationResult registerAttendee(String email, String firstName, String lastName, Address address) {
        // Create the attendee
        Attendee attendee = new Attendee(email, firstName, lastName, address);

        // Here you would typically perform some business logic, like checking if the attendee already exists
        // and then create an event to publish.
        AttendeeRegisteredEvent event = new AttendeeRegisteredEvent(email, attendee.getFullName());
        return new AttendeeRegistrationResult(attendee, event);
    }

    public String getEmail() {
        return email;
    }

    public String getFullName() {
        return firstName + " " + lastName;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public Address getAddress() {
        return address;
    }

    public String getFormattedAddress(){
        return this.address.getFormattedAddress();
    }

}
```

## Key Design Decisions

1. **Enhanced Fields**: Added `firstName`, `lastName`, and `address` fields to capture more detailed attendee information
2. **Factory Method**: The `registerAttendee` static method serves as a factory method that encapsulates the creation logic
3. **Business Behavior**: The `getFullName()` method demonstrates how aggregates can contain business behavior
4. **Event Generation**: The registration process generates a domain event, following event-driven architecture principles


## Important Notes

- The `getFullName()` method demonstrates how domain objects can contain behavior, not just data
- The static factory method `registerAttendee` ensures that attendee creation follows business rules
- The aggregate maintains its invariants while providing a clean interface to the outside world

## Next Step

Continue to [Step 4: Update the AttendeeRegisteredEvent](04-Update-the-Event.md)
