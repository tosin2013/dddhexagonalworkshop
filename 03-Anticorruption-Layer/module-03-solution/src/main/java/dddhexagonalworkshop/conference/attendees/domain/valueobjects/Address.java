package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

/**
 * "A Value Object, or simply a Value, models an immutable conceptual whole. Within the
 * model the Value is just that, a value. Unlike an Entity, it does not have a unique identity,
 * and equivalence is determined by comparing the attributes encapsulated by the Value
 * type. Furthermore, a Value Object is not a thing but is often used to describe, quantify, or
 * measure an Entity."
 * Vaughan Vernon, Domain-Driven Design Distilled
 *
 * @param street
 * @param street2
 * @param city
 * @param stateOrProvince
 * @param postCode
 * @param country
 */
public record Address(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
}
