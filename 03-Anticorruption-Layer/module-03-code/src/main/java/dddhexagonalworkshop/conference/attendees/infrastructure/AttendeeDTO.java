package dddhexagonalworkshop.conference.attendees.infrastructure;

import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

/**
 * DTO (Data Transfer Object) for Attendee.  DTOs are not specifically a DDD concept.
 */
public record AttendeeDTO(String email, String fullName) {
}
