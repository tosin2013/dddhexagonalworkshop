# Step 1: Review Existing External System Classes

## Overview

In this step, we'll review the existing classes that represent the Salesteam external system's data model. These classes have been stubbed out for you and demonstrate how external systems often have their own terminology and data structures that differ from our domain model.

## Understanding External System Models

External system models:

- Use **their own terminology** (Customer vs Attendee)
- Have **different data structures** than our domain
- May have **different business rules** and constraints
- **Change independently** of our system
- Require **translation** to work with our domain

## External System Classes

The classes implementing the following fictional Salesteam JSON document:

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
    VEGETARIAN, GLUTEN_FREE, NONE;
}
```

**Key Observations:**

- Limited set of dietary options
- May not match our domain's meal preference model exactly
- Uses "NONE" instead of other possible defaults

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
- May need mapping to our T-shirt size model
- Different enum values than our domain model

## Differences from Our Domain

### Terminology Differences

- **External**: "Customer" → **Domain**: "Attendee"
- **External**: "DietaryRequirements" → **Domain**: "MealPreference"
- **External**: "Size" → **Domain**: "TShirtSize"

### Structural Differences

- External system groups dietary and size info in `CustomerDetails`
- Our domain likely has these as separate value objects
- External system includes `employer` which may not be stored in our domain

### Data Representation

- External enums may have different values than our domain enums
- External system may have more or fewer options
- Default values might be different

## Why Anti-Corruption Layer is Needed

Without an ACL:

- Our domain would be **contaminated** by external terminology
- Domain model would **depend** on external system changes
- Business logic would be **mixed** with integration concerns
- Testing would be **complicated** by external dependencies

With an ACL:

- Domain model stays **pure** and focused on business concepts
- External changes are **isolated** to the integration layer
- **Clean separation** between integration and domain concerns
- **Independent evolution** of domain and external systems

## Next Step

Continue to [Step 2: Implement the Anti-Corruption Layer Translator](02-Implement-a-Translator.md)
