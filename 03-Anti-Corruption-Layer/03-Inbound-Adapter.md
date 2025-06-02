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

### 1. REST Endpoint Configuration

```java
@Path("/salesteam")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
```

**Design Choices:**
- **Specific path**: `/salesteam` clearly indicates this is for Salesteam integration
- **JSON handling**: Accepts and produces JSON for modern API integration
- **RESTful design**: Uses POST for bulk creation operations

### 2. Dependency Injection

```java
@Inject
AttendeeService attendeeService;
```

**Benefits:**
- **Loose coupling**: Endpoint doesn't create service instances
- **Testability**: Easy to mock AttendeeService for testing
- **Framework integration**: Leverages Quarkus dependency injection

### 3. Request Processing Flow

```java
public Response registerAttendees(SalesteamRegistrationRequest salesteamRegistrationRequest)
```

**Workflow:**
1. **Accept request**: Receive bulk registration data
2. **Log processing**: Track integration activity
3. **Translate data**: Convert external model to domain commands
4. **Process commands**: Execute through domain service
5. **Return response**: Provide appropriate HTTP response

### 4. Anti-Corruption Layer Integration

```java
List<RegisterAttendeeCommand> commands = SalesteamToDomainTranslator.translate(
    salesteamRegistrationRequest.customers()
);
```

**Key Points:**
- **Clean separation**: Endpoint doesn't handle translation logic
- **Single responsibility**: Translation is delegated to specialist class
- **Type safety**: Works with strongly-typed command objects

### 5. Bulk Processing

```java
commands.forEach(attendeeService::registerAttendee);
```

**Processing Strategy:**
- **Method reference**: Clean, functional approach to processing
- **Individual transactions**: Each registration is processed separately
- **Error isolation**: Failures in one registration don't affect others

### 6. Response Handling

```java
return Response.accepted().build();
```

**HTTP Semantics:**
- **202 Accepted**: Indicates request was accepted for processing
- **Asynchronous processing**: Implies processing may continue after response
- **No content**: Simple acknowledgment without detailed response data

## Missing Component: SalesteamRegistrationRequest

You'll need to create the request wrapper:

```java
package dddhexagonalworkshop.conference.attendees.integration.salesteam;

import java.util.List;

public record SalesteamRegistrationRequest(List<Customer> customers) {
}
```

This record:
- **Wraps** the customer list in a proper request object
- **Matches** the expected JSON structure from Salesteam
- **Provides** type safety for the endpoint parameter

## Integration Patterns Demonstrated

### 1. **Adapter Pattern**
- Endpoint adapts external HTTP requests to domain operations
- Translates between REST and domain service interfaces

### 2. **Facade Pattern**
- Endpoint provides simplified interface to complex domain operations
- Hides internal complexity from external systems

### 3. **Batch Processing**
- Efficiently handles multiple registrations in single request
- Reduces network overhead for bulk operations

### 4. **Separation of Concerns**
- Endpoint handles HTTP concerns
- Translator handles data conversion
- Service handles business logic

## Error Handling Considerations

For production systems, enhance with:

```java
@POST
public Response registerAttendees(SalesteamRegistrationRequest request) {
    try {
        Log.infof("Processing %d customer registrations", request.customers().size());
        
        List<RegisterAttendeeCommand> commands = SalesteamToDomainTranslator.translate(
            request.customers()
        );
        
        List<String> errors = new ArrayList<>();
        for (RegisterAttendeeCommand command : commands) {
            try {
                attendeeService.registerAttendee(command);
            } catch (Exception e) {
                Log.errorf("Failed to register attendee %s: %s", command.email(), e.getMessage());
                errors.add("Failed to register " + command.email() + ": " + e.getMessage());
            }
        }
        
        if (errors.isEmpty()) {
            return Response.accepted().build();
        } else {
            return Response.status(207) // Multi-Status
                    .entity(Map.of("errors", errors))
                    .build();
        }
    } catch (Exception e) {
        Log.error("Failed to process registration request", e);
        return Response.serverError()
                .entity(Map.of("error", "Failed to process request"))
                .build();
    }
}
```

## Testing the Endpoint

Example curl command to test:

```bash
curl -X POST http://localhost:8080/salesteam \
  -H "Content-Type: application/json" \
  -d '{
    "customers": [
      {
        "firstName": "John",
        "lastName": "Doe",
        "email": "john.doe@example.com",
        "employer": "Acme Corp",
        "customerDetails": {
          "dietaryRequirements": "VEGETARIAN",
          "size": "L"
        }
      }
    ]
  }'
```

## Next Step

Continue to [Step 4: Update Domain Value Objects](04-Value-Objects.md)
