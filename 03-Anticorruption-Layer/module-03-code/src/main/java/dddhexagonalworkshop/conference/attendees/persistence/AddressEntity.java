package dddhexagonalworkshop.conference.attendees.persistence;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity @Table(name = "attendee_address")
public class AddressEntity {

    @Id @GeneratedValue
    Long id;

    String street;

    String street2;

    String city;

    String stateOrProvince;

    String postCode;

    String country;

    protected AddressEntity() {
    }

    protected AddressEntity(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
        this.street = street;
        this.street2 = street2;
        this.city = city;
        this.stateOrProvince = stateOrProvince;
        this.postCode = postCode;
        this.country = country;
    }

    String getStreet() {
        return street;
    }

    void setStreet(String street) {
        this.street = street;
    }

    String getStreet2() {
        return street2;
    }

    void setStreet2(String street2) {
        this.street2 = street2;
    }

    String getCity() {
        return city;
    }

    void setCity(String city) {
        this.city = city;
    }

    String getStateOrProvince() {
        return stateOrProvince;
    }

    void setStateOrProvince(String stateOrProvince) {
        this.stateOrProvince = stateOrProvince;
    }

    String getPostCode() {
        return postCode;
    }

    void setPostCode(String postCode) {
        this.postCode = postCode;
    }

    String getCountry() {
        return country;
    }

    void setCountry(String country) {
        this.country = country;
    }
}

