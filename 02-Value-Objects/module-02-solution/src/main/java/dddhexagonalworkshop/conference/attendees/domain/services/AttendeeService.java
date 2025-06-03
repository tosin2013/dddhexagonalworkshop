package dddhexagonalworkshop.conference.attendees.domain.services;

import dddhexagonalworkshop.conference.attendees.domain.aggregates.Attendee;
import dddhexagonalworkshop.conference.attendees.infrastructure.AttendeeDTO;
import dddhexagonalworkshop.conference.attendees.infrastructure.AttendeeEventPublisher;
import dddhexagonalworkshop.conference.attendees.persistence.AttendeeRepository;
import io.quarkus.narayana.jta.QuarkusTransaction;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;

/**
 * "The application and domain layers call on the SERVICES provided by the infrastructure layer. When the scope of a SERVICE has been well chosen and its interface well designed, the caller can remain loosely coupled and uncomplicated by the elaborate behavior the SERVICE interface encapsulates."
 * Eric Evans, Domain-Driven Design: Tackling Complexity in the Heart of Software, 2003.
 */

@ApplicationScoped
public class AttendeeService {


    @Inject
    AttendeeRepository attendeeRepository;

    @Inject
    AttendeeEventPublisher attendeeEventPublisher;

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
