# Step 3: Implement the Integration Endpoint

## Overview

In this step, we'll implement the `SalesteamEndpoint` class, which provides a REST API for the external Salesteam system to send bulk registrations. This endpoint demonstrates how to create integration points while maintaining clean architectural boundaries.

## Understanding Integration Endpoints

Integration endpoints:

- **Accept** external system data in their format
- **Coordinate** with Anti-Corruption Layer for translation
- **Delegate** to domain services for business logic
- **Provide** appropriate responses for external systems
- **Handle** bulk operations efficiently

## Implementation

First we need to model the Salesteam payload, which is an Array of Customer objects. We only need a Java record because Quarkus will handle marshalling the objects from JSON:

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

import java.util.List;

public record SalesteamRegistrationRequest(List<Customer> customers) {
}
```

Create the `SalesteamEndpoint` class:

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

        List<RegisterAttendeeCommand> commands = SalesteamToDomainTranslator.translate(
            salesteamRegistrationRequest.customers()
        );

        commands.forEach(attendeeService::registerAttendee);

        return Response.accepted().build();
    }
}
```

## Key Components Analysis


```java
List<RegisterAttendeeCommand> commands = SalesteamToDomainTranslator.translate(
    salesteamRegistrationRequest.customers()
);
```

**Key Points:**

- **Clean separation**: Endpoint doesn't handle translation logic
- **Single responsibility**: Translation is delegated to specialist class
- **Type safety**: Works with strongly-typed command objects


## Testing the Endpoint

You can run this example curl command to test the endpoint from the command line.  This is the same payload the web ui is using.

```bash
curl -X POST \
  http://localhost:8080/salesteam \
  -H 'Content-Type: application/json' \
  -d '[
    {
      "firstName": "Frodo",
      "lastName": "Baggins",
      "email": "frodo.baggins@shire.com",
      "employer": "Shire Council",
      "customerDetails": {
        "dietaryRequirements": "VEG",
        "size": "S"
      }
    },
    {
      "firstName": "Samwise",
      "lastName": "Gamgee",
      "email": "sam.gamgee@shire.com",
      "employer": "Baggins Residence",
      "customerDetails": {
        "dietaryRequirements": "VEG",
        "size": "M"
      }
    },
    {
      "firstName": "Gandalf",
      "lastName": "The Grey",
      "email": "gandalf@middleearth.com",
      "employer": "Wandering Wizard",
      "customerDetails": {
        "dietaryRequirements": "NA",
        "size": "L"
      }
    },
    {
      "firstName": "Aragorn",
      "lastName": "Elessar",
      "email": "aragorn@gondor.com",
      "employer": "King of Gondor",
      "customerDetails": {
        "dietaryRequirements": "NA",
        "size": "XL"
      }
    },
    {
      "firstName": "Legolas",
      "lastName": "Greenleaf",
      "email": "legolas@mirkwood.com",
      "employer": "Mirkwood Forest",
      "customerDetails": {
        "dietaryRequirements": "VEG",
        "size": "M"
      }
    }
  ]'
```

## Next Step

Continue to [Step 4: Update Domain Value Objects](04-Value-Objects.md)
```
