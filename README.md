# Domain Driven Design and Hexagonal Architecture Hands-On Workshop

## Welcome to this Hands-On Workshop!

This workshop is for anyone who likes to get their hands on a keyboard as part of the learning process. Your project authors believe that architecture is best learned through practice, and this workshop provides a structured way to apply Domain-Driven Design (DDD) principles in a practical context.

There is a great deal of theory in Domain Driven Design. This workshop was built because while the authors love talking about software architecture (their colleagues will verify), they also like getting their hands dirty with code. In fact, your workshop authors believe that it is impossible to understand software architecture **_without_** getting your hands on a keyboard and implementing the ideas.

### What We Will Build Today

By the end of this workshop, we will have a **working attendee registration system** that demonstrates core Domain-Driven Design (DDD) patterns using a Hexagonal Architecture at its' core. We will be able to register attendees via a REST API, with events published to Kafka and data persisted to PostgreSQL.

### Our Learning Strategy

Each workshop module contains a pre-built directory with stubbed out classes, like the one below.

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
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter, which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on all sides of it, without actually knowing the nature of the things on the other side of the adapters."
 * Alistair Cockburn, Hexagonal Architecture, 2005.
 *
 */
public class AttendeeEndpoint {
}

```

The documentation contains the code to complete the classes:

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
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter, which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on all sides of it, without actually knowing the nature of the things on the other side of the adapters."
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

You can implement the classes by typing in the supplied code, which is your workshop authors preferred method because we believe it is easier to remember that way, or by copying and pasting.  Each step will cover a particular DDD topic.

The examples are not meant to be reflect a production system so you will find, for instance, that validation might not be as complete as it would in a real application.

#### tl;dr

Each step starts with a **tl;dr** section containing only code.  If you want to get the application up and running as quickly as possible you can copy/paste the code into the stubbed classes without reading the rest of the material.

We think this can be a good approach if you are as impatient as (one of) us, but we hope you go back through the material and read through each step.

---

## Workshop Overview

### What We're Building

A conference attendee registration microservice with:

- **REST API** for registering attendees
- **Business logic** that validates registrations
- **Event publishing** to notify other systems
- **Database persistence** for attendee data
- **Clean architecture** that separates concerns

### The Journey (3 Iterations)

We'll build this system step-by-step, with each piece compiling as we go:

| Iteration | Component                 | Focus                                                                 |
| --------- | ------------------------- | --------------------------------------------------------------------- |
| 01        | **End to End DDD**        | Implement a (very) basic workflow                                     |
| 02        | **Value Objects**         | Add more detail to the basic workflow                                 |
| 03        | **Anti-Corruption Layer** | Implement an Anti Corruption Layer to integrate with external systems |
| 04        | **Testability**           | Focus on testing                                                      |

**Total:** 120 minutes = 2 hours

---

### Iteration 1 (10 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component           | Focus                       |
| ---- | ------------------- | --------------------------- |
| 01   | **Events**          | Capture business facts      |
| 02   | **Commands**        | Represent business requests |
| 03   | **Result Objects**  | Combine multiple outputs    |
| 04   | **Aggregates**      | Core business logic         |
| 05   | **Entities**        | Database mapping            |
| 06   | **Repositories**    | Data access layer           |
| 07   | **Event Publisher** | Messaging integration       |
| 08   | **Domain Services** | Workflow orchestration      |
| 09   | **DTOs**            | API data contracts          |
| 10   | **REST Endpoint**   | HTTP interface              |

**Total:** 106 minutes + 14 minutes buffer = 2 hours

---

### Iteration 2 (7 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Focus                       |
| ---- | -------------------------------------- | --------------------------- |
| 01   | **Create the Address Value Object**    | Capture business facts      |
| 02   | **Update the RegisterAttendeeCommand** | Represent business requests |
| 03   | **Update the Attendee Aggregate**      | Package multiple outputs    |
| 04   | **Update the AttendeeRegisteredEvent** | Core business logic         |
| 05   | **Update the Persistence Layer**       | Database mapping            |
| 06   | **Update the AttendeeService**         | Data access layer           |
| 07   | **Update the AttendeeDTO**             | Messaging integration       |

**Total:** 106 minutes + 14 minutes buffer = 2 hours

---

### Iteration 3 (7 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Focus                       |
| ---- | -------------------------------------- | --------------------------- |
| 01   | **Create the Address Value Object**    | Capture business facts      |
| 02   | **Update the RegisterAttendeeCommand** | Represent business requests |
| 03   | **Update the Attendee Aggregate**      | Package multiple outputs    |
| 04   | **Update the AttendeeRegisteredEvent** | Core business logic         |
| 05   | **Update the Persistence Layer**       | Database mapping            |
| 06   | **Update the AttendeeService**         | Data access layer           |
| 07   | **Update the AttendeeDTO**             | Messaging integration       |

**Total:** 106 minutes + 14 minutes buffer = 2 hours

## Key Concepts We'll Experience

### Domain-Driven Design (DDD)

- **Business logic in the right place** - not scattered across layers
- **Rich domain models** that express business concepts clearly
- **Clean separation** between business rules and technical concerns

### Hexagonal Architecture

- **Ports and Adapters** pattern that keeps your core domain pure
- **Technology independence** - swap databases or frameworks easily
- **Testable design** with clear boundaries

### The Big Picture

```
External World → REST → Domain Logic → Events → External Systems
     ↓              ↓         ↓           ↓           ↓
  HTTP Requests → Commands → Aggregates → Events → Kafka
                     ↓         ↓           ↓
                  DTOs ← Domain Service → Repository → Database
```

---

## Your Learning Path

### 🚀 **Workshop**

- **Goal:** Working end-to-end system
- **Approach:** Copy code, compile, and understand the basics
- **Questions:** Ask questions at any time!

### 📚 **Extra Stuff**

- **Deep-dive materials** explaining the "why" behind what you built
- **Advanced patterns** for production systems
- **Additional iterations** to extend your knowledge

---

## Step-by-Step Preview

### Steps 1-3: Building Blocks

**Events, Commands, Result Objects**

- **Events:** Capture what happened in the business
- **Commands:** Represent requests for action
- **Result Objects:** Clean way to return multiple values

_These establish the vocabulary of your domain._

### Step 4: The Heart

**Aggregates**

- **Where business logic lives**
- **Enforces business rules and invariants**
- **Coordinates creating events and domain objects**

_This is the core of Domain-Driven Design._

### Steps 5-6: Persistence

**Entities and Repositories**

- **Entities:** Map domain objects to database tables
- **Repositories:** Abstract data access behind domain interfaces

_Clean separation between domain model and database concerns._

### Steps 7: Outbound Adapters

**Event Publisher**

- **Event Publisher:** Send domain events to external systems

_Hexagonal Architecture in action - adapters for external systems._

### Steps 8: Services

**Domain Services**

- **Domain Services:** Orchestrate complex business workflows

_Orchestrating the Domain_

### Steps 9-10: Inbound Adapters

**DTOs and REST Endpoint**

- **DTOs:** Clean contracts for API responses
- **REST Endpoint:** HTTP interface to your domain

_External interface that exposes your domain capabilities._

---

## Workshop Rules for Success

### ✅ **Do This:**

- **Follow along step-by-step** - don't jump ahead
- **Copy code exactly** - worry about understanding later
- **Ask for help** if you get stuck
- **Focus on getting it working** - theory comes later

### ❌ **Avoid This:**

- **Don't try to understand everything** during live coding
- **Don't optimize or change the code** - get it working first
- **Don't get stuck on theory questions** - ask questions!

### 🆘 **If You Fall Behind:**

- **Don't panic** - the goal is learning, not perfection
- **Revisit at a later date** - the workshop will be on GitHub, and the authors are easy to get in touch with

---

## Pre-Workshop Checklist

### Required Setup (Should be done already)

- [ ] **Java 21+** installed and working
- [ ] **Maven 3.8+** installed and working
- [ ] **IDE** (IntelliJ, VS Code, Eclipse) ready
- [ ] **Workshop repository** cloned
- [ ] **Starter project** compiles: `mvn compile`

## Get Started!

[01 End to End DDD](01-End-to-End-DDD/README.md)
