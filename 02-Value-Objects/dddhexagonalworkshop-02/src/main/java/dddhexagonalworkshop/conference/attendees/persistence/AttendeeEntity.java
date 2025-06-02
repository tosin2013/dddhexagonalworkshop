package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;

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

    private String email;

    /* Default, no-arg constructor required by Hibernate, which we are using as our JPA provider.
     */
    protected AttendeeEntity() {
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
}
