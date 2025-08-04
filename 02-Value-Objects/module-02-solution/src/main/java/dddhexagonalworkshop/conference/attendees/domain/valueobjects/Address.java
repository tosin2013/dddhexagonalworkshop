package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public record Address(String streetAddress, String bus, String postalCode, String townOrMunicipality) {

    public Address {
        if (streetAddress == null || streetAddress.isBlank()) {
            throw new IllegalArgumentException("Street address cannot be null or blank");
        }
        if (postalCode == null || postalCode.isBlank()) {
            throw new IllegalArgumentException("Postal code cannot be null or blank");
        }
        if (townOrMunicipality == null || townOrMunicipality.isBlank()) {
            throw new IllegalArgumentException("City cannot be null or blank");
        }
    }
}
