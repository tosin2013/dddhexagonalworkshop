# Iteration 02: Adding Value Objects

## tl;dr

Create an `Address` Value Object:

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public record Address(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
}
```

Update the `RegisterAttendeeCommand`:

```java
public record RegisterAttendeeCommand(String email, String firstName, String lastName, Address address) {
}
```

Update the `Attendee` Aggregate:

```java
package dddhexagonalworkshop.conference.attendees.domain;

import dddhexagonalworkshop.conference.attendees.domain.events.AttendeeRegisteredEvent;
import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeRegistrationResult;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

public class Attendee {

    String email;

    String firstName;

    String lastName;

    Address address;

    public Attendee(String email, String firstName, String lastName, Address address) {
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.address = address;
    }

    public static AttendeeRegistrationResult registerAttendee(String email, String firstName, String lastName, Address address) {
        // Here you would typically perform some business logic, like checking if the attendee already exists
        // and then create an event to publish.
        AttendeeRegisteredEvent event = new AttendeeRegisteredEvent(email, this.getFullName());
        return new AttendeeRegistrationResult(this, event);
    }

    public String getEmail() {
        return email;
    }

    String getFullName() {
        return firstName + " " + lastName;
    }

    String getFirstName() {
        return firstName;
    }

    String getLastName() {
        return lastName;
    }

    public Address getAddress() {
        return address;
    }
}
```

Update the `AttendeeRegisteredEvent`:

```java
package dddhexagonalworkshop.conference.attendees.domain.events;

public record AttendeeRegisteredEvent(String email, String fullName) {
}
```

Add an `AddressEntity` Entity:

```java
package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.Embeddable;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

@Entity @Table(name = "attendee_address")
public class AddressEntity {

    @Id @GeneratedValue
    private Long id;

    String street;

    String street2;

    String city;

    String stateOrProvince;

    String postCode;

    String country;

    protected AddressEntity() {
    }

    protected AddressEntity(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
        this.street = street;
        this.street2 = street2;
        this.city = city;
        this.stateOrProvince = stateOrProvince;
        this.postCode = postCode;
        this.country = country;
    }

    String getStreet() {
        return street;
    }

    void setStreet(String street) {
        this.street = street;
    }

    String getStreet2() {
        return street2;
    }

    void setStreet2(String street2) {
        this.street2 = street2;
    }

    String getCity() {
        return city;
    }

    void setCity(String city) {
        this.city = city;
    }

    String getStateOrProvince() {
        return stateOrProvince;
    }

    void setStateOrProvince(String stateOrProvince) {
        this.stateOrProvince = stateOrProvince;
    }

    String getPostCode() {
        return postCode;
    }

    void setPostCode(String postCode) {
        this.postCode = postCode;
    }

    String getCountry() {
        return country;
    }

    void setCountry(String country) {
        this.country = country;
    }
}
```

Update the `AttendeeEntity`:

```java
package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.*;

@Entity @Table(name = "attendee")
public class AttendeeEntity {

    @Id @GeneratedValue
    private Long id;

    @OneToOne(cascade = CascadeType.ALL)
    AddressEntity address;

    private String email;

    protected AttendeeEntity() {
    }

    protected AttendeeEntity(String email, AddressEntity address) {
        this.email = email;
        this.address = address;
    }

    protected Long getId() {
        return id;
    }

    protected String getEmail() {
        return email;
    }

}
```

Update the `AttendeeRepository`:

```java
package dddhexagonalworkshop.conference.attendees.persistence;

import dddhexagonalworkshop.conference.attendees.domain.aggregates.Attendee;
import io.quarkus.hibernate.orm.panache.PanacheRepository;

public class AttendeeRepository implements PanacheRepository<AttendeeEntity> {


    public void persist(Attendee aggregate) {
        // transform the aggregate to an entity
        AttendeeEntity attendeeEntity = fromAggregate(aggregate);
        persist(attendeeEntity);
    }

    private AttendeeEntity fromAggregate(Attendee attendee) {
        AddressEntity addressEntity = new AddressEntity(
                attendee.getAddress().street(),
                attendee.getAddress().street2(),
                attendee.getAddress().city(),
                attendee.getAddress().stateOrProvince(),
                attendee.getAddress().postCode(),
                attendee.getAddress().country()
        );
        AttendeeEntity entity = new AttendeeEntity(attendee.getEmail(), addressEntity);
        return entity;
    }
}
```

Update the `AttendeeService`:

```java
package dddhexagonalworkshop.conference.attendees.domain.services;

import dddhexagonalworkshop.conference.attendees.domain.aggregates.Attendee;
import dddhexagonalworkshop.conference.attendees.infrastrcture.AttendeeDTO;
import dddhexagonalworkshop.conference.attendees.infrastrcture.AttendeeEventPublisher;
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
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand registerAttendeeAttendeeCommand) {
        // Logic to register an attendee
        AttendeeRegistrationResult result = Attendee.registerAttendee(registerAttendeeAttendeeCommand.email(),
                registerAttendeeAttendeeCommand.firstName(),
                registerAttendeeAttendeeCommand.lastName(),
                registerAttendeeAttendeeCommand.address());


        //persist the attendee
        QuarkusTransaction.requiringNew().run(() -> {
            attendeeRepository.persist(result.attendee());
        });

        //notify the system that a new attendee has been registered
        attendeeEventPublisher.publish(result.attendeeRegisteredEvent());

        return new AttendeeDTO(result.attendee().getEmail(), result.attendee().getFullName());
    }
}
```

## What We Are Building

In this iteration we will enhance the `Attendee` model by adding an address field. This will allow us to store more detailed information about each attendee using **Value Objects** - a core Domain Driven Design concept.

We will also use the `Hexagonal Architecture`, or `Ports and Adapters` pattern to integrate with external systems, ensuring a clean separation of concerns.

## Learning Objectives

- **Value Objects**: Objects that describe the state of something else, equal based on their value rather than identity
- **Hexagonal Architecture**: Maintaining clean boundaries between domain, persistence, and infrastructure layers

## Technology Stack

**Quarkus** (https://quarkus.io) is a modern Java framework designed for building cloud-native applications. It provides a set of tools and libraries that make it easy to develop, test, and deploy applications. In this workshop, we will leverage Quarkus to implement our DDD concepts and build a RESTful API for registering attendees.

The project uses Quarkus features including:

- Built-in support for REST endpoints
- JSON serialization
- Database access
- `Dev Mode` that automatically spins up external dependencies like Kafka and PostgreSQL

## Project Structure

The basic project structure is already set up for you:

```text
dddhexagonalworkshop
├── conference
│   └── attendees
│       ├── domain
│       │   ├── aggregates
│       │   │   └── Attendee.java
│       │   ├── events
│       │   │   └── AttendeeRegisteredEvent.java
│       │   ├── services
│       │   │   ├── AttendeeRegistrationResult.java
│       │   │   └── AttendeeService.java
│       │   │   └── RegisterAttendeeCommand.java
│       │   └── valueobjects
│       │       └── Address.java
│       ├── infrastructure
│       │   ├── AttendeeEndpoint.java
│       │   ├── AttendeeDTO.java
│       │   └── AttendeeEventPublisher.java
│       └── persistence
│           ├── AttendeeEntity.java
│           └── AttendeeRepository.java
```

## Workshop Steps

This iteration is divided into the following steps:

1. **[Step 1: Create the Address Value Object](step1-address-value-object.md)**
2. **[Step 2: Update the RegisterAttendeeCommand](step2-update-command.md)**
3. **[Step 3: Update the Attendee Aggregate](step3-update-attendee.md)**
4. **[Step 4: Update the AttendeeRegisteredEvent](step4-update-event.md)**
5. **[Step 5: Update the Persistence Layer](step5-update-persistence.md)**
6. **[Step 6: Update the AttendeeDTO](step6-update-dto.md)**
7. **[Step 7: Update the AttendeeService](step7-update-service.md)**

## How to Use This Workshop

As you progress through the workshop, you will fill in the missing pieces of code in the appropriate packages. The workshop authors have stubbed out the classes so that you can focus on the Domain Driven Design concepts as much as possible and Java and framework concepts as little as possible.

You can:

- Type in the code line by line
- Copy and paste the code provided into your IDE
- Combine both approaches as you see fit

The goal is to understand the concepts and how they fit together in a DDD context.

## Expected Outcome

By the end of this iteration, you'll have:

- A solid understanding of Value Objects in DDD
- An enhanced Attendee model with proper address encapsulation
- Experience with evolving domain models while maintaining clean architecture
- A working application that demonstrates hexagonal architecture principles

Let's get coding!
