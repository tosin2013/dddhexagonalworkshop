# Step 5: Update the RegisterAttendeeCommand

## Overview

In this final step, we need to update the `RegisterAttendeeCommand` to include the new value objects we created: `MealPreference` and `TShirtSize`. This ensures our command can capture all the information that external systems might provide through the Anti-Corruption Layer.

## Command Evolution in DDD

Commands evolve to:

- **Capture** new business requirements
- **Support** additional data sources
- **Maintain** backward compatibility
- **Provide** complete information for domain operations
- **Enable** rich domain modeling

## Updated Implementation

Update the `RegisterAttendeeCommand` to include the new fields:

```java
package dddhexagonalworkshop.conference.attendees.domain.services;

import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.MealPreference;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.TShirtSize;

public record RegisterAttendeeCommand(
        String email,
        String firstName,
        String lastName,
        Address address,
        MealPreference mealPreference,
        TShirtSize tShirtSize
) {
}
```

## Key Changes

### 1. Enhanced Data Capture

**Previous version:**

```java
public record RegisterAttendeeCommand(String email, String firstName, String lastName, Address address)
```

**New version:**

```java
public record RegisterAttendeeCommand(
    String email,
    String firstName,
    String lastName,
    Address address,
    MealPreference mealPreference,  // New
    TShirtSize tShirtSize          // New
)
```

### 2. Value Object Integration

The command now uses:

- **Domain-specific types**: `MealPreference` and `TShirtSize`
- **Type safety**: Compile-time guarantees about valid values
- **Rich modeling**: Value objects with business behavior

### 3. Support for Multiple Data Sources

The enhanced command supports data from:

- **Direct registration**: Users entering their
