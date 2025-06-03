package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.*;

@Entity
public class AddressEntity {

    @Id
    @GeneratedValue
    private Long id;

    private String streetAddress;

    private String bus;

    private String postalCode;

    private String townOrMunicipality;

    protected AddressEntity() {
    }

    protected AddressEntity(String streetAddress, String bus, String postalCode, String townOrMunicipality) {
        this.streetAddress = streetAddress;
        this.bus = bus;
        this.postalCode = postalCode;
        this.townOrMunicipality = townOrMunicipality;
    }

    Long getId() {
        return id;
    }

    void setId(Long id) {
        this.id = id;
    }

    String getStreetAddress() {
        return streetAddress;
    }

    void setStreetAddress(String streetAddress) {
        this.streetAddress = streetAddress;
    }

    String getBus() {
        return bus;
    }

    void setBus(String bus) {
        this.bus = bus;
    }

    String getPostalCode() {
        return postalCode;
    }

    void setPostalCode(String postalCode) {
        this.postalCode = postalCode;
    }

    String getTownOrMunicipality() {
        return townOrMunicipality;
    }

    void setTownOrMunicipality(String city) {
        this.townOrMunicipality = city;
    }
}
