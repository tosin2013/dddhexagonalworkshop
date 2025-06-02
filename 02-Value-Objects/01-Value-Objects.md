# Step 1: Create the Address Value Object

## tl;dr

Create an `Address` Value Object:

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public record Address(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
}
```

## Learning Objectives

- Understanding Value Objects
- Understand the differences between Entities an Value Objects
- Implement a Value Object for `Address`
  
## Why Value Objects Matter

Value Objects are objects that describe the state of something else. They are not Entities, which have continuity and identify something that is tracked over time.

- **Value Objects** are equal based on their **value**
- **Entities** are equal based on their **identifier**

## Implementation

In this step, we will create a `Value Object` to represent the address of an attendee. This will allow us to encapsulate the address data in a single object, making it easier to manage and validate.

The `Address` Value Object can be found in the `dddhexagonalworkshop.conference.attendees.domain.valueobjects` package.

### Basic Implementation

Update the `Address` object with the following fields:

- String street
- String street2
- String city
- String stateOrProvince
- String postCode
- String country

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public record Address(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
}
```

### Optional: Enhanced Implementation with Validation

Add validation to the Address record to ensure that all fields are properly formatted and not empty.

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public record Address(String street, String street2, String city, String stateOrProvince, String postCode, String country) {
    /**
     * Compact constructor for validation
     */
    public Address {
        validate(street, city, stateOrProvince, postCode, country);
    }

    /**
     * Validates that the address components are properly formatted.
     *
     * @throws IllegalArgumentException if the address is invalid
     */
    private void validate(String street, String city, String stateOrProvince, String postCode, String country) {
        if (street == null || street.isBlank()) {
            throw new IllegalArgumentException("Street cannot be empty");
        }

        if (city == null || city.isBlank()) {
            throw new IllegalArgumentException("City cannot be empty");
        }

        if (stateOrProvince == null || stateOrProvince.isBlank()) {
            throw new IllegalArgumentException("State or province cannot be empty");
        }

        if (postCode == null || postCode.isBlank()) {
            throw new IllegalArgumentException("Postal code cannot be empty");
        }

        if (country == null || country.isBlank()) {
            throw new IllegalArgumentException("Country cannot be empty");
        }

        if (street.length() > 100) {
            throw new IllegalArgumentException("Street is too long (max 100 characters)");
        }

        if (city.length() > 50) {
            throw new IllegalArgumentException("City is too long (max 50 characters)");
        }

        if (stateOrProvince.length() > 50) {
            throw new IllegalArgumentException("State or province is too long (max 50 characters)");
        }

        if (postCode.length() > 20) {
            throw new IllegalArgumentException("Postal code is too long (max 20 characters)");
        }

        if (country.length() > 50) {
            throw new IllegalArgumentException("Country is too long (max 50 characters)");
        }
    }

    /**
     * Returns a formatted single-line address string.
     *
     * @return formatted address
     */
    public String getFormattedAddress() {
        StringBuilder sb = new StringBuilder(street);
        if (street2 != null && !street2.isBlank()) {
            sb.append(", ").append(street2);
        }
        sb.append(", ").append(city)
                .append(", ").append(stateOrProvince)
                .append(" ").append(postCode)
                .append(", ").append(country);
        return sb.toString();
    }

    @Override
    public String toString() {
        return getFormattedAddress();
    }
}
```

## Next Step

Continue to [Step 2: Update the RegisterAttendeeCommand](step2-update-command.md)
