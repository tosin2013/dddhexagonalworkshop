package dddhexagonalworkshop.conference.attendees.domain.aggregates;

import dddhexagonalworkshop.conference.attendees.domain.events.AttendeeRegisteredEvent;
import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeRegistrationResult;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

/**
 * "An AGGREGATE is a cluster of associated objects that we treat as a unit for the purpose of data changes. Each AGGREGATE has a root and a boundary. The boundary defines what is inside the AGGREGATE. The root is a single, specific ENTITY contained in the AGGREGATE. The root is the only member of the AGGREGATE that outside objects are allowed to hold references to, although objects within the boundary may hold references to each other."
 * Eric Evans, Domain-Driven Design: Tackling Complexity in the Heart of Software, 2003
 */
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

    public String getFullName() {
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