# Step 1: Review Existing External System Classes

## Overview

This module is based on integrating with a fictional partner named "Salesteam."  Salesteam provides a service that registers conference attendees.  They, of course, have their Ubiquitous Language, which is different from ours.  We will integrate with Salesteam using an Anticorruption layer, which is the most defensive of integration patterns.

In this step, we'll review the existing classes that represent the Salesteam external system's data model. These classes have been stubbed out for you so you don't need to implement them; just review them so that you are familiar before continuing.

## Understanding External System Models

The Salesteam system:

- Uses **its' own terminology** (Customer vs Attendee)
- Has **different data structures** than our domain
- May have **different business rules** and constraints
- **Changes independently** of our system

## External System Classes

The following classes implement this JSON payload:

```json
{
  "customers": [
    {
      "firstName": "string",
      "lastName": "string",
      "email": "string",
      "employer": "string",
      "customerDetails": {
        "dietaryRequirements": "VEGETARIAN|GLUTEN_FREE|NONE",
        "size": "XS|S|M|L|XL|XXL"
      }
    }
  ]
}
```

### Customer.java

Represents a customer in the Salesteam system:

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public record Customer(String firstName, String lastName, String email, String employer, CustomerDetails customerDetails) {
}
```

**Key Observations:**

- Uses "Customer" terminology instead of "Attendee"
- Includes `employer` field that may not be relevant to our domain
- References `CustomerDetails` for additional information

### CustomerDetails.java

Represents additional details about a customer:

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public record CustomerDetails(DietaryRequirements dietaryRequirements, Size size) {
}
```

**Key Observations:**

- Groups dietary and size information together
- Uses external system's enums for these values

### DietaryRequirements.java

External system's representation of dietary needs:

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public enum DietaryRequirements {
    VEG, GLF, NA;
}
```

**Key Observations:**

- The `DietaryRequirements` does not match our `MealPreference`

### Size.java

External system's representation of clothing sizes:

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public enum Size {
    XS, S, M, L, XL, XXL;
}
```

**Key Observations:**

- Includes XS size that our domain might not support
- Different enum values than our domain model
- Will require mapping to our T-shirt size model

## Differences from Our Domain

### Terminology Differences

- **External**: "Customer" → **Domain**: "Attendee"
- **External**: "DietaryRequirements" → **Domain**: "MealPreference"
- **External**: "Size" → **Domain**: "TShirtSize"

### Structural Differences

- External system groups dietary and size info in `CustomerDetails`
- External system includes `employer` which may not be stored in our domain


## Why Anticorruption Layer Matters

Without an anticorruption layer:

- Our domain would be **contaminated** by external terminology
- Our domain model would **depend** on external system changes
- Business logic would be **mixed** with integration concerns
- Testing would be **complicated** by external dependencies

By implementing an anticorruption layer:

- Our domain model stays **pure** using only our own ubiquitous language
- External changes are **isolated** to the integration layer
- **Clean separation** between integration and domain concerns
- **Independent evolution** of domain and external systems

## Next Step

Continue to [Step 2: Implement the Anti-Corruption Layer Translator](02-Implement-a-Translator.md)
