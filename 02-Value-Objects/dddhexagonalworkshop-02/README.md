# Workshop Workflow

## Iteration 02: Adding Value Objects

### DDD Concepts: Value Objects

### Overview

### Overview
In this iteration we will enhance the `Attendee` model by adding an address field. This will allow us to store more detailed information about each attendee.

**Introduction:**
In this iteration, we will enhance the `Attendee` model by adding an address field. This will allow us to store more detailed information about each attendee.
- Value Objects

We will alss use the `Hexangonal Architecture`, or `Ports and Adapters` pattern to integrate with external systems, ensuring a clean separation of concerns.

The basic project structure is already set up for you. The project is structured as follows:

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
As you progress through the workshop, you will fill in the missing pieces of code in the appropriate packages.  The workshop authors have stubbed out the classes so that you can focus on the Domain Driven Design concepts as much as possible and Java and framework concepts as little as possilb. 
You can type in the code line by line or copy and paste the code provided into your IDE. You can also combine the approaches as you see fit. The goal is to understand the concepts and how they fit together in a DDD context.


**Quarkus**

Quarkus, https://quarkus.io, is a modern Java framework designed for building cloud-native applications. It provides a set of tools and libraries that make it easy to develop, test, and deploy applications. In this workshop, we will leverage Quarkus to implement our DDD concepts and build a RESTful API for registering attendees.
The project uses Quarkus, a Java framework that provides built-in support for REST endpoints, JSON serialization, and database access.  Quarkus also features a `Dev Mode` that automatically spins up external dependencies like Kafka and PostgreSQL, allowing you to focus on writing code without worrying about the underlying infrastructure.

**Steps:**

In this first iteration, we will implement the basic workflow for registering an attendee. The steps are as follows:

1. 

By the end of Iteration 1, you'll have a solid foundation in DDD concepts and a very basic working application.

Let's get coding!

### Step 1: Create the Address Value Object

Value Objects are objects that describe the state of something else.  They are not Entities, which have continuity and identify something that is tracked over time.  Value Objects are equal based on their value while Entites are equal based on their identifier.

In this iteration, we will create a `Value Object` to represent the address of an attendee. This will allow us to encapsulate the address data in a single object, making it easier to manage and validate.

The `Address` Value Object can be found in the `dddhexagonalworkshop.conference.attendees.domain.valueobjects` package.  Update the `Address` object with the following value: 
- String email
- String street
- String street2
- String city
- String stateOrProvince
- String postCode
- String country

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public record Address(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
}
```

***Optional:***

Add validation to the Address record to ensure that all fields are properly formatted and not empty.

```java
public record Address(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
    /**
     * Compact constructor for validation
     */
    public Address {
        validate(street, city, stateOrProvince, postCode, country);
    }

    /**
     * Validates that the address components are properly formatted.
     *
     * @throws IllegalArgumentException if the address is invalid
     */
    private void validate(String street, String city, String stateOrProvince, String postCode, String country) {
        if (street == null || street.isBlank()) {
            throw new IllegalArgumentException("Street cannot be empty");
        }

        if (city == null || city.isBlank()) {
            throw new IllegalArgumentException("City cannot be empty");
        }

        if (stateOrProvince == null || stateOrProvince.isBlank()) {
            throw new IllegalArgumentException("State or province cannot be empty");
        }

        if (postCode == null || postCode.isBlank()) {
            throw new IllegalArgumentException("Postal code cannot be empty");
        }

        if (country == null || country.isBlank()) {
            throw new IllegalArgumentException("Country cannot be empty");
        }

        if (street.length() > 100) {
            throw new IllegalArgumentException("Street is too long (max 100 characters)");
        }

        if (city.length() > 50) {
            throw new IllegalArgumentException("City is too long (max 50 characters)");
        }

        if (stateOrProvince.length() > 50) {
            throw new IllegalArgumentException("State or province is too long (max 50 characters)");
        }

        if (postCode.length() > 20) {
            throw new IllegalArgumentException("Postal code is too long (max 20 characters)");
        }

        if (country.length() > 50) {
            throw new IllegalArgumentException("Country is too long (max 50 characters)");
        }
    }

    /**
     * Returns a formatted single-line address string.
     *
     * @return formatted address
     */
    public String getFormattedAddress() {
        StringBuilder sb = new StringBuilder(street);
        if (street2 != null && !street2.isBlank()) {
            sb.append(", ").append(street2);
        }
        sb.append(", ").append(city)
                .append(", ").append(stateOrProvince)
                .append(" ").append(postCode)
                .append(", ").append(country);
        return sb.toString();
    }

    @Override
    public String toString() {
        return getFormattedAddress();
    }
}
```



#### 2. Update the Add the RegisterAttendeeCommand

First, update the `RegisterAttendeeCommand` to include the new address field along with first and last name fields.

```java
public record RegisterAttendeeCommand(String email, String firstName, String lastName, Address address) {
}
```

#### 3. Update the `Attendee` aggregate model

Update the `Attendee` aggregate model to include the new address field and first and last name fields.

NOTE: We are creating a method, "getFullName", to return the full name of the attendee by concatenating the first and last names.

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
#### 4. Update the `AttendeeRegisteredEvent`

Add the attendee's full name to `AttendeeRegisteredEvent`.  We won't add the address to the event, as it is not necessary for the rest of the system. 

If, in the future, a different Bounded Context needs an attendee's address, we can work with the team that owns that Bounded Context to implement a method for them to query our microservice for the attendee's address.

```java
package dddhexagonalworkshop.conference.attendees.domain.events;

public record AttendeeRegisteredEvent(String email, String fullName) {
}
```
#### 5. Update the persistence layer to handle the new fields

First, create a new `AddressEntity` class to represent the address in the persistence layer.

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

Second, add the new fields to the `AttendeeEntity` class in the persistence layer.

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

Third, update the `AttendeeRepository` to handle the new fields:

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

#### 6. Update the AttendeeDTO

First update the `AttendeeDTO` that is used to transfer data between the service and the controller to include the new address field.

```java
package dddhexagonalworkshop.conference.attendees.infrastrcture;

import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

public record AttendeeDTO(String email, String fullName) {
}
```

#### 7. Update the AttendeeService

Second, update the `AttendeeService` to handle the new fields:

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

## Summary

In this iteration, we implemented an Address value object to enhance the Attendee model. The address information is now properly encapsulated in a dedicated value object, following DDD principles. We updated the entire workflow from command handling through domain logic to persistence to support addresses, maintaining clean boundaries between the different layers of our hexagonal architecture.

### Key points
- Value Objects: We implemented the Address as a value object - an immutable representation of address data without its own identity, following core DDD principles.
- Domain Model Enhancement: We extended the Attendee aggregate to include address information, demonstrating how to evolve domain models while maintaining encapsulation.
- Persistence Layer Updates: We created a dedicated AddressEntity with a one-to-one relationship to AttendeeEntity, showing how to map complex domain objects to relational storage.
- Command Pattern: We modified the RegisterAttendeeCommand to include address information, illustrating how commands can evolve to capture new requirements.
- Hexagonal Architecture: Throughout the changes, we maintained separation between domain, persistence, and infrastructure layers, demonstrating how hexagonal architecture allows for changes while maintaining boundaries.
- Transaction Management: We used Quarkus transactions to ensure atomicity when persisting related entities, showing how to handle complex persistence operations.
