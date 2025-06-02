# Workshop Workflow

## Iteration 03: Integrating with Extenral Systems with an Anti-Corruption Layer

### DDD Concepts: Anti-Corruption Layer

### Overview

In this module we will integrate with a fictitious external service, "Salesteam," that registers customers and sends the registrations over in bulk. "Salesteam" provides a JSON document that contains customer information, including their first name, last name, email, employer, and dietary requirements.

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

We will implement an Anti-Corruption Layer (ACL) to ensure that our domain model remains clean and unaffected by the external system's data structure. The Anti-Corruption Layer, or ACL, will translate the external service's data into our domain model, allowing us to work with our own abstractions while still integrating with the external system.

The basic project structure is already set up for you. The project is structured as follows:

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
│       │       ├── SalesteamEndpoint.java
│       │       ├── SalesteamRegistrationRequest.java
│       │       └── SalesteamToDomainTranslator.java
│       └── persistence
│           ├── AttendeeEntity.java
│           └── AttendeeRepository.java
```

As you progress through the workshop, you will fill in the missing pieces of code in the appropriate packages. The workshop authors have stubbed out the classes so that you can focus on the Domain Driven Design concepts as much as possible and Java and framework concepts as little as possilb.
You can type in the code line by line or copy and paste the code provided into your IDE. You can also combine the approaches as you see fit. The goal is to understand the concepts and how they fit together in a DDD context.

**Quarkus**

Quarkus, https://quarkus.io, is a modern Java framework designed for building cloud-native applications. It provides a set of tools and libraries that make it easy to develop, test, and deploy applications. In this workshop, we will leverage Quarkus to implement our DDD concepts and build a RESTful API for registering attendees.
The project uses Quarkus, a Java framework that provides built-in support for REST endpoints, JSON serialization, and database access. Quarkus also features a `Dev Mode` that automatically spins up external dependencies like Kafka and PostgreSQL, allowing you to focus on writing code without worrying about the underlying infrastructure.

**Steps:**

#### 1. Review the Existing Classes

The classes implementing the Salesteam JSON document are already stubbed out for you. You can find them in the `dddhexagonalworkshop.conference.attendees.integration.salesteam` package. The classes are:

- `Customer.java`: Represents a customer in the Salesteam system.
- `CustomerDetails.java`: Represents the details of a customer, including dietary requirements and size.
- `DietaryRequirements.java`: An enum representing the dietary requirements of a customer.
- `Size.java`: An enum representing the size of a customer.

We will implement the other two classes, `SalesteamEndpoint.java` and `SalesteamToDomainTranslator`in this iteration.

##### `Customer.java`

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public record Customer(String firstName, String lastName, String email, String employer, CustomerDetails customerDetails) {
}
```

##### `CustomerDetails.java`

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public record CustomerDetails(DietaryRequirements dietaryRequirements, Size size) {
}
```

##### `DietaryRequirements.java`

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public enum DietaryRequirements {
    VEGETARIAN, GLUTEN_FREE, NONE;
}
```

##### `Size.java`

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

public enum Size {
    XS, S, M, L, XL, XXL;
}
```

#### 2. Implement the `SalesteamToDomainTranslator.java`

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.MealPreference;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.TShirtSize;

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

#### 3. Implement the `SalesteamEndpoint.java`

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;
import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeService;
import io.quarkus.logging.Log;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/salesteam")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class SalesteamEndpoint {

    @Inject
    AttendeeService attendeeService;

    @POST
    public Response registerAttendees(SalesteamRegistrationRequest salesteamRegistrationRequest) {
        Log.debugf("Registering attendees for %s", salesteamRegistrationRequest);

        List<RegisterAttendeeCommand> commands = SalesteamToDomainTranslator.translate(salesteamRegistrationRequest.customers());
        commands.forEach(attendeeService::registerAttendee);
        return Response.accepted().build();
    }
}

```

## Summary

In this iteration, we implemented an Anti-Corruption Layer (ACL) to integrate with an external system called "Salesteam." The ACL translates between the external system's data model (Customers with CustomerDetails) and our domain model (Attendees with Addresses, MealPreferences, and TShirtSizes). This approach protects our domain model from being contaminated by external concepts and terminology.

The implementation consisted of two key components:

A translator class that converts external data structures to domain commands
An endpoint that receives bulk registration requests and processes them through our domain service

### Key points

- Anti-Corruption Layer: The ACL pattern provides a protective boundary between our domain model and external systems, ensuring our domain remains "pure" and focused on core business concepts.
- Model Translation: We implemented mapping logic to convert external concepts (like DietaryRequirements) to our domain concepts (like MealPreference), maintaining the integrity of our domain language.
- Loose Coupling: The ACL allows our domain to evolve independently from external systems. Changes to the Salesteam API structure would only require changes to the translator, not our core domain.
- Integration Patterns: The endpoint demonstrates how to receive bulk data and process it through our domain services, showing how external systems can integrate with our bounded context.
- Domain Protection: By translating external data into our RegisterAttendeeCommand objects, we ensure that all domain validation rules and business logic are still applied, even to data from external sources.
- Clean Boundaries: The integration package provides a clear separation between external systems and our domain, making the codebase easier to understand and maintain.
