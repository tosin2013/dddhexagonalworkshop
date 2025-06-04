# A Hands On Introduction to Domain-Driven Design and Hexagonal Architecture Workshop

Welcome to the **Domain-Driven Design (DDD) with Hexagonal Architecture Workshop**! This hands-on workshop will guide you through implementing core DDD concepts while building a demo registration system for conference attendees.

This workshop is for anyone who likes to get their hands on a keyboard as part of the learning process. Your project authors believe that architecture is best learned through practice, and this workshop provides a structured way to apply Domain-Driven Design (DDD) principles in a practical context.

There is a great deal of theory in Domain Driven Design. This workshop was built because while the authors love talking about software architecture (their colleagues will verify), they also like getting their hands dirty with code. In fact, your workshop authors believe that it is impossible to understand software architecture **_without_** getting your hands on a keyboard and implementing the ideas.

## 🎯 Workshop Overview

This workshop is for anyone who likes to get their hands on a keyboard as part of the learning process. Your project authors believe that architecture is best learned through practice, and this workshop provides a structured way to apply Domain-Driven Design (DDD) principles in a practical context.

In this introductory workshop, you'll learn to apply Domain-Driven Design principles by building a microservice for managing conference attendee registrations. You'll implement the complete workflow from receiving HTTP requests to persisting data and publishing events, all while maintaining clean architectural boundaries.

### What We'll Build

By the end of this workshop, you will have implemented an attendee registration system that demonstrates:

- **Domain-Driven Design**: Business-focused modeling and implementation
- **Event-Driven Communication**: Asynchronous integration through domain events
- **Hexagonal Architecture**: Creation of loosely coupled application components that can be easily composed; also known as ports and adapters
- **Inbound Adapters**: HTTP endpoint implementation
- **Outbound Adapters**: Persistent storage with proper domain/persistence separation and messaging with Kafka

## 🏗️ Architecture Overview

This workshop implements the **Hexagonal Architecture** (Ports and Adapters) pattern, ensuring your business logic remains independent of external technologies:

```
External World → Inbound Adapters → Domain Layer → Outbound Adapters → External Systems
     ↓                ↓               ↓              ↓                    ↓
HTTP Requests → REST Endpoints    → Business Logic   → Event Publisher    → Kafka
                                    Aggregates       → Repository         → Database
```

## 📚 Core DDD Concepts Covered

### 🎪 **Aggregates**

The heart of DDD - business entities that encapsulate logic and maintain consistency within their boundaries.

### 📋 **Events & Commands**

- **Events**: Record facts that have already occurred (immutable) and most importantly _what the business cares about_.
- **Commands**: Represent intentions to change state (can fail)

### 🔧 **Application Services**

Orchestrate business workflows that don't naturally belong in a single aggregate.

### 📦 **Entities**

Model your domain with appropriate object types that reflect business concepts.

### 🗃️ **Repositories**

Provide a collection-like interface for accessing and persisting aggregates, abstracting database details.

### 🔌 **Adapters**

Integration points between the domain and external systems (REST APIs, databases, message queues).

### 📦 **Value Objects**

Model your domain with appropriate object types that reflect business concepts.


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
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter,   * which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on   * all sides of it, without actually knowing the nature of the things on the other side of the adapters."
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
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter,   * which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on   * all sides of it, without actually knowing the nature of the things on the other side of the adapters."
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

### :rocket: tl;dr

Each step starts with a **tl;dr** section containing only code.  If you want to get the application up and running as quickly as possible you can copy/paste the code into the stubbed classes without reading the rest of the material.

We think this can be a good approach if you are as impatient as (one of) us, but we hope you go back through the material and read through each step.

---

## Workshop Overview

### What We Are Building

A conference attendee registration microservice with:

- **REST API** for registering attendees
- **Business logic** that validates registrations
- **Event publishing** to notify other systems
- **Database persistence** for attendee data
- **Clean architecture** that separates concerns

### The Journey (3 Modules)

We'll build this system step-by-step, with each piece compiling as we go:

| Module | Component                 | Focus                                                                 |
| --------- | ------------------------- | --------------------------------------------------------------------- |
| [01](/01-End-to-End-DDD/Overview.md)        | **End to End DDD**        | Implement a (very) basic workflow                                     |
| [02](/02-Value-Objects/Overview.md)        | **Value Objects**         | Add more detail to the basic workflow                                 |
| [03](/03-Anti-Corruption-Layer.md)        | **Anti-Corruption Layer** | Implement an Anti Corruption Layer to integrate with external systems |
| [04](/04-Testing/Overview.md)        | **Testability**           | Focus on testing                                                      |

---

### Module 1 (10 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component           | Focus                       |
| ---- | ------------------- | --------------------------- |
| [01](/01-End-to-End-DDD/01-Events.md)   | **Events**          | Capture business facts      |
| [02](/01-End-to-End-DDD/02-Commands.md)   | **Commands**        | Represent business requests |
| [03](/01-End-to-End-DDD/03-Combining-Return-Values.md)   | **Result Objects**  | Combine multiple outputs    |
| [04](/01-End-to-End-DDD/04-Aggregates.md)   | **Aggregates**      | Core business logic         |
| [05](/01-End-to-End-DDD/05-Entities.md)   | **Entities**        | Database mapping            |
| [06](/01-End-to-End-DDD/06-Repositories.md)   | **Repositories**    | Data access layer           |
| [07](/01-End-to-End-DDD/07-Outbound-Adapters.md)   | **Event Publisher** | Messaging integration       |
| [08](/01-End-to-End-DDD/08-Application-Services.md)   | **Domain Services** | Workflow orchestration      |
| [09](/01-End-to-End-DDD/09-Data-Transfer-Objects.md)   | **DTOs**            | API data contracts          |
| [10](/01-End-to-End-DDD/10-Inbound-Adapters.md)   | **REST Endpoint**   | HTTP interface              |

---

### Module 2 (7 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Focus                       |
| ---- | -------------------------------------- | --------------------------- |
| [01](/02-Value-Objects/01-Value-Objects.md)   | **Create the Address Value Object**    | Capture business facts      |
| [02](/02-Value-Objects/02-Update-the-Command.md)   | **Update the RegisterAttendeeCommand** | Represent business requests |
| [03](/02-Value-Objects/03-Update-the-Aggregate.md)   | **Update the Attendee Aggregate**      | Package multiple outputs    |
| [04](/02-Value-Objects/04-Update-the-Event.md)   | **Update the AttendeeRegisteredEvent** | Core business logic         |
| [05](/02-Value-Objects/05-Update-Persistence.md)   | **Update the Persistence Layer**       | Database mapping            |
| [06](/02-Value-Objects/06-Update-the-DTO.md)   | **Update the AttendeeService**         | Data access layer           |
| [07](/02-Value-Objects/07-Update-the-Service.md)   | **Update the AttendeeDTO**             | Messaging integration       |

---

### Module 3 (5 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Focus                       |
| ---- | -------------------------------------- | --------------------------- |
| [01](03-Anti-Corruption-Layer/01-The-External-System.md)   | **Create the Address Value Object**    | Capture business facts      |
| [02](03-Anti-Corruption-Layer/02-Implement-a-Translator.md)   | **Update the RegisterAttendeeCommand** | Represent business requests |
| [03](03-Anti-Corruption-Layer/03-Inbound-Adapter.md)   | **Update the Attendee Aggregate**      | Package multiple outputs    |
| [04](03-Anti-Corruption-Layer/04-Value-Objects.md)   | **Update the AttendeeRegisteredEvent** | Core business logic         |
| [05](03-Anti-Corruption-Layer/05-Update-the-Command.md)   | **Update the Persistence Layer**       | Database mapping            |


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

## Workshop Rules for Success

### ✅ **Do This:**

- **Follow along step-by-step** - don't jump ahead
- **Copy code exactly** - before experimenting.  Once everything is working, experiment all you want
- **Ask for help** if you get stuck

### ❌ **Avoid This:**

- **Don't optimize or change the code** - get it working first
- **Don't get stuck on theory questions** - ask theory questions!
- **Don't get stuck on implementation questions** - ask implementation questions!

### 🆘 **If You Fall Behind:**

- **Don't panic** - the goal is learning, not perfection
- **Revisit at a later date** - the workshop will be on GitHub, the authors are easy to get in touch with, and happy to help at any time

---

## Hands-on-Keyboards Checklist 

There are 2 ways to do the workshop:

- GitHub Codespace: [GitHub Codespaces](GitHub-Codespaces.md)

- Quarkus' Dev Mode on your laptop: [Quarkus Local](Quarkus-Local.md)

### Why Quarkus?

- **⚡ Supersonic, Subatomic Java**: Incredibly fast startup times and low memory usage
- **🔧 Developer Experience**: Live reload during development - see changes instantly
- **🐳 Container First**: Built for Kubernetes and cloud deployment from the ground up
- **📦 Unified Configuration**: Single configuration model for all extensions
- **🎯 Standards-Based**: Built on proven standards like JAX-RS, CDI, and JPA

Most importantly, Quarkus gets out of your way, allowing you to focus on your code.

Your workshop authors work for Red Hat, the company behind Quarkus, but we believe that Quarkus is the best choice because it allows you to focus on implementing Domain-Driven Design (DDD) concepts without worrying about boilerplate code or complex configurations.

[Quarkus Website](https://quarkus.io/)

### Workshop-Specific Benefits

**Dev Mode Magic**: Quarkus automatically starts and manages external dependencies:

```bash
./mvnw quarkus:dev
```

This single command spins up:

- PostgreSQL database for persistence
- Kafka broker for event streaming
- Your application with live reload
- Integrated testing capabilities

**Zero Configuration Complexity**: Focus on DDD concepts instead of infrastructure setup. Quarkus handles:

- Database schema generation
- Kafka topic creation
- Dependency injection
- REST endpoint configuration
- JSON serialization

## Get Started!

[01 End to End DDD](01-End-to-End-DDD/README.md)
