# Module 3: Integrating with External Systems with an Anticorruption Layer

## Overview

In this iteration we will integrate with a fictitious external service, "Salesteam," that registers customers and sends the registrations over in bulk. We will implement an **Anti-Corruption Layer (ACL)** to ensure that our domain model remains clean and unaffected by the external system's data structure.

There are multiple apporaches for integrating with external systems.  We will be using an Anticorruption Layer which is the most defensive pattern and completely isolates our Bounded Context from the external system.

***_Note_***: our Domain Model has been extended for this Module with two new classes, MealPreference and TShirtSize. Both classes can be found in the `dddhexagonalworkshop.conference.attendees.domain.valueobjects` package. 

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public enum MealPreference {
    NONE, VEGETARIAN, GLUTEN_FREE;
}
```

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

public enum TShirtSize {
    S, M, L, XL, XXL;
}
```

## DDD Concepts Covered

- **Anticorruption Layer**: A protective boundary between our domain model and external systems
- **Model Translation**: Converting external concepts to domain concepts
- **Integration Patterns**: How external systems can integrate with bounded contexts
- **Domain Protection**: Maintaining domain integrity when integrating with external systems

## External System Integration

The "Salesteam" system provides customer data in the following JSON format:

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

## Anti-Corruption Layer Benefits

The ACL will:

- **Translate** the external service's data into our domain model
- **Protect** our domain from external system changes
- **Maintain** clean separation between bounded contexts
- **Enable** independent evolution of our domain model

## Project Structure

The project structure has been enhanced with integration components:

```text
dddhexagonalworkshop
├── conference
│   └── attendees
│       ├── domain
│       │   ├── aggregates
│       │   │   └── Attendee.java
│       │   ├── events
│       │   │   └── AttendeeRegisteredEvent.java
│       │   ├── services
│       │   │   ├── AttendeeRegistrationResult.java
│       │   │   ├── AttendeeService.java
│       │   │   └── RegisterAttendeeCommand.java
│       │   └── valueobjects
│       │       ├── Address.java
│       │       ├── MealPreference.java
│       │       └── TShirtSize.java
│       ├── infrastructure
│       │   ├── AttendeeEndpoint.java
│       │   ├── AttendeeDTO.java
│       │   └── AttendeeEventPublisher.java
│       ├── integration
│       │   └── salesteam
│       │       ├── Customer.java
│       │       ├── CustomerDetails.java
│       │       ├── DietaryRequirements.java
│       │       ├── Size.java
│       │       ├── SalesteamEndpoint.java
│       │       ├── SalesteamRegistrationRequest.java
│       │       └── SalesteamToDomainTranslator.java
│       └── persistence
│           ├── AttendeeEntity.java
│           └── AttendeeRepository.java
```

## Workshop Steps

This iteration is divided into the following steps:

1. **[Step 1: Review Existing External System Classes](step1-review-external-classes.md)**
2. **[Step 2: Implement the Anti-Corruption Layer Translator](step2-implement-translator.md)**
3. **[Step 3: Implement the Integration Endpoint](step3-implement-endpoint.md)**
4. **[Step 4: Update Domain Value Objects](step4-update-value-objects.md)**
5. **[Step 5: Update the RegisterAttendeeCommand](step5-update-command.md)**

## Key Learning Objectives

- **Boundary Protection**: How ACL protects domain models from external influence
- **Model Translation**: Converting between different data representations
- **Integration Patterns**: Clean ways to integrate with external systems
- **Domain Purity**: Keeping domain models focused on business concepts

Let's get coding!

First step: [The External System](01-The-External-System.md)
