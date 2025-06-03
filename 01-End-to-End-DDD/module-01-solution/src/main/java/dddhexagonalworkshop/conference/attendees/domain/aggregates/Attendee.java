package dddhexagonalworkshop.conference.attendees.domain.aggregates;

import dddhexagonalworkshop.conference.attendees.domain.events.AttendeeRegisteredEvent;
import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeRegistrationResult;

/**
 * "An AGGREGATE is a cluster of associated objects that we treat as a unit for the purpose of data changes. Each AGGREGATE has a root and a boundary. The boundary defines what is inside the AGGREGATE. The root is a single, specific ENTITY contained in the AGGREGATE. The root is the only member of the AGGREGATE that outside objects are allowed to hold references to, although objects within the boundary may hold references to each other."
 * Eric Evans, Domain-Driven Design: Tackling Complexity in the Heart of Software, 2003
 */
public class Attendee {

    String email;

    protected Attendee(String email) {
        this.email = email;
    }

    public static AttendeeRegistrationResult registerAttendee(String email) {
        // Here you would typically perform some business logic, like checking if the attendee already exists
        // and then create an event to publish.
        Attendee attendee = new Attendee(email);
        AttendeeRegisteredEvent event = new AttendeeRegisteredEvent(email);
        return new AttendeeRegistrationResult(attendee, event);
    }

    public String getEmail(){
        return email;
    }
}
