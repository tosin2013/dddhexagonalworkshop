# Step 2: Implement the Anti-Corruption Layer Translator

## Overview

In this step, we'll implement the `SalesteamToDomainTranslator` class, which is the heart of our Anti-Corruption Layer. This translator converts external system data into our domain model, protecting our domain from external changes and terminology.

***_Note_***: We have 2 new fields in our Attendee, MealPreference and TShirtSize.  These have been added to better illustrate the translation


## Understanding Translation in ACL

The translator:

- **Converts** external models to domain commands
- **Maps** external terminology to domain concepts
- **Handles** differences in data structure and representation
- **Protects** the domain from external system changes
- **Centralizes** integration logic in one place

## Implementation

Create the `SalesteamToDomainTranslator` class:

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

import dddhexagonalworkshop.conference.attendees.domain.valueobjects.TShirtSize;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.MealPreference;
import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;

import java.util.List;

public class SalesteamToDomainTranslator {

    public static List<RegisterAttendeeCommand> translate(List<Customer> customers) {
        return customers.stream()
                .map(customer -> new RegisterAttendeeCommand(
                        customer.email(),
                        customer.firstName(),
                        customer.lastName(),
                        null,
                        mapDietaryRequirements(customer.customerDetails().dietaryRequirements()),
                        mapTShirtSize(customer.customerDetails().size()))).toList();
    }

    private static MealPreference mapDietaryRequirements(DietaryRequirements dietaryRequirements) {
        if (dietaryRequirements == null) {
            return MealPreference.NONE;
        }
        return switch (dietaryRequirements) {
            case VEG -> MealPreference.VEGETARIAN;
            case GLF -> MealPreference.GLUTEN_FREE;
            case NA -> MealPreference.NONE;
        };
    }

    private static TShirtSize mapTShirtSize(Size size) {
        if (size == null) {
            return null;
        }
        return switch (size) {
            case Size.XS -> TShirtSize.S;
            case Size.S -> TShirtSize.S;
            case Size.M -> TShirtSize.M;
            case Size.L -> TShirtSize.L;
            case Size.XL -> TShirtSize.XL;
            case Size.XXL -> TShirtSize.XXL;
            default -> null;
        };
    }
}
```

## Key Translation Decisions

### 1. Main Translation Method

```java
public static List<RegisterAttendeeCommand> translate(List<Customer> customers)
```

**Design Choices:**

- **Static method**: Simple utility function for translation
- **Batch processing**: Handles lists of customers efficiently
- **Command pattern**: Converts to domain commands rather than domain objects directly
- **Stream API**: Leverages functional programming for clean transformation

### 2. Address Handling

```java
null, // No address provided by Salesteam
```

**Strategic Decision:**

- Salesteam doesn't provide address information
- We set address to `null` rather than creating a default
- This preserves data integrity - we don't make up missing information
- Future enhancement could prompt for address collection separately

### 3. Dietary Requirements Mapping

```java
private static MealPreference mapDietaryRequirements(DietaryRequirements dietaryRequirements)
```

**Mapping Strategy:**

- **One-to-one mapping**: External enums map directly to domain enums
- **Null safety**: Handles null values gracefully
- **Default handling**: Null external values become `MealPreference.NONE`
- **Switch expression**: Modern Java syntax for clean mapping

### 4. T-Shirt Size Mapping

```java
case XS -> TShirtSize.S;  // XS maps to S (no XS in our domain)
```

**Business Logic in Translation:**

- **Size coercion**: XS external size maps to S in our domain
- **Business decision**: Our domain doesn't support XS, so we map to closest size
- **Data preservation**: All other sizes map directly
- **Null handling**: Preserves null values appropriately

## Anti-Corruption Layer Principles Demonstrated

### 1. **Terminology Translation**

- `Customer` → `RegisterAttendeeCommand`
- `DietaryRequirements` → `MealPreference`
- `Size` → `TShirtSize`

### 2. **Structural Translation**

- Flat customer structure → Command with value objects
- `CustomerDetails` grouping → Separate domain concepts

### 3. **Business Logic Isolation**

- Size mapping rules contained in ACL
- Domain model doesn't know about XS → S mapping
- Integration-specific decisions stay in integration layer

### 4. **Error Boundaries**

- Null handling at integration boundary
- Invalid data doesn't reach domain
- Clear failure modes for integration issues

## Benefits of This Approach

1. **Domain Protection**: Domain model never sees external terminology
2. **Change Isolation**: External system changes only affect the translator
3. **Business Logic Clarity**: Domain focuses on core business, ACL handles integration
4. **Testing Simplicity**: Can test translation logic independently
5. **Maintainability**: Integration concerns are centralized

## Potential Enhancements

For production systems, consider:

- **Validation**: Check data quality before translation
- **Logging**: Track translation decisions and issues
- **Error Handling**: Robust handling of malformed external data
- **Metrics**: Monitor translation success rates
- **Configuration**: Make mapping rules configurable

## Next Step

Continue to [Step 3: Implement the Integration Endpoint](03-Inbound-Adapter.md)
