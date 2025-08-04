# Step 10: Wrapping Up With an Inbound Adapter (REST Endpoint)

## tl;dr

_If you want to get the application up and running as quickly as possible you can copy/paste the code into the stubbed classes without reading the rest of the material._

Inbound adapters translate between external protocols and domain operations. Our REST endpoint handles HTTP concerns while delegating business logic to domain services:

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeService;
import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;
import io.quarkus.logging.Log;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.net.URI;


/**
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out,
 * it sends it out through a port to an adapter, which creates the appropriate signals needed by the receiving technology
 * (human or automated). The application has a semantically sound interaction with the adapters on all sides of it, without
 * actually knowing the nature of the things on the other side of the adapters."
 *
 * Alistair Cockburn, Hexagonal Architecture, 2005.
 *
 */
@Path("/attendees")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class AttendeeEndpoint {

    @Inject
    AttendeeService attendeeService;

    @POST
    public Response registerAttendee(RegisterAttendeeCommand registerAttendeeCommand) {
        Log.debugf("Creating attendee %s", registerAttendeeCommand);

        AttendeeDTO attendeeDTO = attendeeService.registerAttendee(registerAttendeeCommand);

        Log.debugf("Created attendee %s", attendeeDTO);

        return Response.created(URI.create("/" + attendeeDTO.email())).entity(attendeeDTO).build();
    }

}
```

## Learning Objectives
- **Understand** Inbound Adapters as the entry point for external requests into the domain
- **Implement** AttendeeEndpoint as a REST adapter using JAX-RS
- **Apply** Hexagonal Architecture principles to decouple HTTP concerns from business logic
- **Complete** the end-to-end DDD workflow from HTTP request to domain operation

## What You'll Build
An `AttendeeEndpoint` REST controller that serves as the inbound adapter, handling HTTP requests, delegating to domain services, and returning JSON responses while maintaining clean architectural boundaries.

## Why Inbound Adapters Are Critical

Inbound Adapters solve the fundamental problem of **how external systems interact with your domain** without polluting business logic with technology-specific concerns:

**The Technology Intrusion Problem**: Without adapters, HTTP concerns leak into domain logic:

❌ HTTP concerns mixed with business logic

```java
public class AttendeeService {
    public Response registerAttendee(HttpServletRequest request) {
        // HTTP parsing in domain service!
        String email = request.getParameter("email");
        if (email == null) {
            return Response.status(400).entity("Email required").build();
        }
        
        // Domain logic mixed with HTTP response handling
        try {
            Attendee attendee = Attendee.registerAttendee(email);
            String json = objectMapper.writeValueAsString(attendee);
            return Response.ok(json).build();
        } catch (Exception e) {
            return Response.status(500).entity("Server error").build();
        }
    }
}
```

✅ Clean separation through inbound adapter

**The Inbound Adapter Solution**: Clean separation between HTTP and domain:
```java
@Path("/attendees")
public class AttendeeEndpoint {
    @Inject AttendeeService attendeeService;  // Domain interface
    
    @POST
    public Response register(RegisterAttendeeCommand command) {
        // Adapter handles HTTP specifics
        AttendeeDTO result = attendeeService.registerAttendee(command);
        return Response.created(URI.create("/" + result.email())).entity(result).build();
    }
}

// Domain service stays pure
public class AttendeeService {
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand command) {
        // Pure business logic, no HTTP concerns
    }
}
```

## Hexagonal Architecture: Inbound vs Outbound Deep Dive

Understanding the flow of data through hexagonal architecture is crucial for proper adapter implementation:

### Adapter Flow Patterns

| Flow Type | Direction | Purpose | Examples | Initiator |
|-----------|-----------|---------|----------|-----------|
| **Inbound (Primary)** | External → Domain | Receive requests | REST, GraphQL, CLI, Events | External systems |
| **Outbound (Secondary)** | Domain → External | Send commands/queries | Database, Messaging, Email | Domain logic |

### Inbound Adapter Responsibilities

| Responsibility | Description | Example |
|----------------|-------------|---------|
| **Protocol Translation** | Convert external protocols to domain calls | HTTP → Domain Commands |
| **Input Validation** | Validate external input format | JSON schema, field validation |
| **Authentication/Authorization** | Security boundary enforcement | JWT validation, role checks |
| **Error Translation** | Convert domain errors to external format | Domain exceptions → HTTP status codes |
| **Content Negotiation** | Handle different response formats | JSON, XML, CSV responses |
| **Rate Limiting** | Protect domain from overload | Request throttling, circuit breakers |

Most of these responsibilites are handled by your framework.  It is a principle of Domain Driven Design that your application not be too reliant upon frameworks.  We agree that framework code should be as transparent as possible, which is why we are using Quarkus, but we absolutely want to use frameworks to make our lives easier!

Next: [Module 1 Summary](Summary.md)








