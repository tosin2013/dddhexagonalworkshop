package dddhexagonalworkshop.conference.attendees.persistence;

import dddhexagonalworkshop.conference.attendees.domain.aggregates.Attendee;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

/**
 * "A REPOSITORY represents all objects of a certain type as a conceptual set (usually emulated). It acts like a collection, except with more elaborate querying capability. Objects of the appropriate type are added and removed, and the machinery behind the REPOSITORY inserts them or deletes them from the database."
 * Eric Evans, Domain-Driven Design: Tackling Complexity in the Heart of Software, 2003.
 *
 * We are using PanacheRepository from Quarkus, which provides a set of methods to interact with the database.
 */
@ApplicationScoped
public class AttendeeRepository implements PanacheRepository<AttendeeEntity> {

    public void persist(Attendee aggregate) {
        // transform the aggregate to an entity
        AttendeeEntity attendeeEntity = fromAggregate(aggregate);
        persist(attendeeEntity);
    }

    private AttendeeEntity fromAggregate(Attendee attendee) {
        if(attendee.getAddress() == null) {
            return new AttendeeEntity(attendee.getEmail());
        }else {
            AddressEntity addressEntity = new AddressEntity(
                    attendee.getAddress().street(),
                    attendee.getAddress().street2(),
                    attendee.getAddress().city(),
                    attendee.getAddress().stateOrProvince(),
                    attendee.getAddress().postCode(),
                    attendee.getAddress().country()
            );
            return new AttendeeEntity(attendee.getEmail(), addressEntity);
        }
    }
}
