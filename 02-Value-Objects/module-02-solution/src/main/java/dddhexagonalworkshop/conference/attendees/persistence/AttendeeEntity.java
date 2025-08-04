package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.*;

/**
 * "An Entity models an individual thing. Each Entity has a unique identity in that you can
 * distinguish its individuality from among all other Entities of the same or a different type."
 * Vaugn Vernon, Domain-Driven Design Distilled, 2016
 *
 */
@Entity
public class AttendeeEntity {

    @Id
    @GeneratedValue
    private Long id;

    private String firstName;

    private String lastName;

    private String email;

    @OneToOne(cascade = CascadeType.ALL)
    AddressEntity address;

    /* Default, no-arg constructor required by Hibernate, which we are using as our JPA provider.
     */
    protected AttendeeEntity() {
    }

    AttendeeEntity(String firstName, String lastName, String email, AddressEntity address) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.email = email;
        this.address = address;
    }

    protected AttendeeEntity(String email) {
        this.email = email;
    }

    protected Long getId() {
        return id;
    }

    protected String getEmail() {
        return email;
    }

    protected String getFirstName() {
        return firstName;
    }

    protected String getLastName() {
        return lastName;
    }

    protected AddressEntity getAddress() {
        return address;
    }
}
