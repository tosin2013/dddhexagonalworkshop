# Step 5: Update the Persistence Layer

## Overview

In this step, we'll update the persistence layer to handle the new address fields. This demonstrates how to map complex domain objects to relational database structures while maintaining clean separation between domain and persistence concerns.

## Hexagonal Architecture Principles

The persistence layer:

- Implements the repository port defined by the domain
- Translates between domain objects and database entities
- Handles the technical concerns of data storage
- Keeps database concerns out of the domain

## Implementation Steps

### Step 5.1: Create the AddressEntity

First, create a new `AddressEntity` class to represent the address in the persistence layer:

```java
package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.*;

@Entity
@Table(name = "attendee_address")
public class AddressEntity {

    @Id
    @GeneratedValue
    private Long id;

    private String street;
    private String street2;
    private String city;
    private String stateOrProvince;
    private String postCode;
    private String country;

    protected AddressEntity() {
        // JPA requires no-arg constructor
    }

    public AddressEntity(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
        this.street = street;
        this.street2 = street2;
        this.city = city;
        this.stateOrProvince = stateOrProvince;
        this.postCode = postCode;
        this.country = country;
    }

    // Getters and setters
    public String getStreet() {
        return street;
    }

    public void setStreet(String street) {
        this.street = street;
    }

    public String getStreet2() {
        return street2;
    }

    public void setStreet2(String street2) {
        this.street2 = street2;
    }

    public String getCity() {
        return city;
    }

    public void setCity(String city) {
        this.city = city;
    }

    public String getStateOrProvince() {
        return stateOrProvince;
    }

    public void setStateOrProvince(String stateOrProvince) {
        this.stateOrProvince = stateOrProvince;
    }

    public String getPostCode() {
        return postCode;
    }

    public void setPostCode(String postCode) {
        this.postCode = postCode;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }
}
```

### Step 5.2: Update the AttendeeEntity

Add the new address field and first/last name fields to the `AttendeeEntity` class:

```java
package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.*;

@Entity
@Table(name = "attendee")
public class AttendeeEntity {

    @Id
    @GeneratedValue
    private Long id;

    @OneToOne(cascade = CascadeType.ALL)
    @JoinColumn(name = "address_id")
    private AddressEntity address;

    private String email;
    private String firstName;
    private String lastName;

    protected AttendeeEntity() {
        // JPA requires no-arg constructor
    }

    public AttendeeEntity(String email, String firstName, String lastName, AddressEntity address) {
        this.email = email;
        this.firstName = firstName;
        this.lastName = lastName;
        this.address = address;
    }

    // Getters and setters
    public Long getId() {
        return id;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getFirstName() {
        return firstName;
    }

    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public void setLastName(String lastName) {
        this.lastName = lastName;
    }

    public AddressEntity getAddress() {
        return address;
    }

    public void setAddress(AddressEntity address) {
        this.address = address;
    }
}
```

### Step 5.3: Update the AttendeeRepository

Update the `AttendeeRepository` to handle the new fields and provide mapping between domain and persistence objects:

```java
package dddhexagonalworkshop.conference.attendees.persistence;

import dddhexagonalworkshop.conference.attendees.domain.aggregates.Attendee;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class AttendeeRepository implements PanacheRepository<AttendeeEntity> {

    public void persist(Attendee aggregate) {
        // Transform the aggregate to an entity
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

        return new AttendeeEntity(
                attendee.getEmail(),
                attendee.getFirstName(),
                attendee.getLastName(),
                addressEntity
        );
    }

    // Method to convert from entity back to domain object (for future use)
    private Attendee toAggregate(AttendeeEntity entity) {
        Address address = new Address(
                entity.getAddress().getStreet(),
                entity.getAddress().getStreet2(),
                entity.getAddress().getCity(),
                entity.getAddress().getStateOrProvince(),
                entity.getAddress().getPostCode(),
                entity.getAddress().getCountry()
        );

        return new Attendee(
                entity.getEmail(),
                entity.getFirstName(),
                entity.getLastName(),
                address
        );
    }
}
```

## Key Design Decisions

1. **Separate Entity Classes**: Domain objects and persistence entities are separate, maintaining clean boundaries
2. **One-to-One Relationship**: Address gets its own table and entity, demonstrating normalized database design
3. **Cascade Operations**: `CascadeType.ALL` ensures address entities are managed with attendee entities
4. **Mapping Methods**: Clear separation between domain-to-entity and entity-to-domain transformations

## Database Schema Implications

This will create two tables:

- `attendee`: Contains attendee information and a foreign key to address
- `attendee_address`: Contains address information

## Next Step

Continue to [Step 6: Update the AttendeeDTO](step6-update-dto.md)
