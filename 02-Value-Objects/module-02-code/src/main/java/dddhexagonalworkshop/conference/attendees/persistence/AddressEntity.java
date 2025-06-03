package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.*;

@Entity
public class AddressEntity {

    @Id
    @GeneratedValue
    private Long id;

    protected AddressEntity() {
    }

}
