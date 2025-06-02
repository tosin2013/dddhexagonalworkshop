# Module 3: Integrating with External Systems with an Anti-Corruption Layer

## Overview

In this iteration we will integrate with a fictitious external service, "Salesteam," that registers customers and sends the registrations over in bulk. We will implement an **Anti-Corruption Layer (ACL)** to ensure that our domain model remains clean and unaffected by the external system's data structure.

## DDD Concepts Covered

- **Anti-Corruption Layer**: A protective boundary between our domain model and external systems
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

## Technology Stack

**Quarkus** (https://quarkus.io) continues to provide:

- Built-in support for REST endpoints
- JSON serialization and deserialization
- Dependency injection
- `Dev Mode` with automatic infrastructure setup

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

## How to Use This Workshop

As you progress through the workshop, you will fill in the missing pieces of code in the appropriate packages. The workshop authors have stubbed out the classes so that you can focus on the Domain Driven Design concepts as much as possible and Java and framework concepts as little as possible.

You can:

- Type in the code line by line
- Copy and paste the code provided into your IDE
- Combine both approaches as you see fit

The goal is to understand the concepts and how they fit together in a DDD context.

## Expected Outcome

By the end of this iteration, you'll have:

- A solid understanding of Anti-Corruption Layer patterns
- Experience with model translation between external and domain models
- A working integration that protects your domain model
- Knowledge of how to maintain domain integrity when integrating with external systems

## Key Learning Points

- **Boundary Protection**: How ACL protects domain models from external influence
- **Model Translation**: Converting between different data representations
- **Integration Patterns**: Clean ways to integrate with external systems
- **Domain Purity**: Keeping domain models focused on business concepts

Let's get coding!

First step: [01-The-External-System](01-The-External-System.md)
