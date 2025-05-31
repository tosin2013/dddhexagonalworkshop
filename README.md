# Domain Driven Design and Hexagonal Architecture Hands-On Workshop

# Domain-Driven Design with Hexagonal Architecture Workshop

## Welcome! (2-Hour Hands-On Workshop)

There is a great deal of theory in Domain Driven Design. This workshop was built because while the authors love talking about software architecture (their colleagues will verify), they also like getting their hands dirty with code. In fact, your workshop authors believe that it is impossible to understand software architecture **_without_** getting your hands on a keyboard and implementing the ideas.

### What You'll Build Today

By the end of this workshop, you'll have a **complete, working attendee registration system** that demonstrates core Domain-Driven Design (DDD) patterns within a Hexagonal Architecture. You'll be able to register attendees via REST API, with events published to Kafka and data persisted to PostgreSQL.

### Our Learning Strategy

**⚡ Live Session (2 hours):** Focus on getting working code with minimal theory
**📚 Self-Study Materials:** Deep-dive explanations for later learning

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

| Iteration | Component                 | Time   | Focus                                                                 |
| --------- | ------------------------- | ------ | --------------------------------------------------------------------- |
| 01        | **End to End DDD**        | 60 min | Implement a (very) basic workflow                                     |
| 02        | **Value Objects**         | 15 min | Add more detail to the basic workflow                                 |
| 03        | **Anti-Corruption Layer** | 30 min | Implement an Anti Corruption Layer to integrate with external systems |
| 04        | **Testability**           | 15 min | Focus on testing                                                      |

**Total:** 120 minutes = 2 hours

---

### Iteration 1 (10 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component           | Time   | Focus                       |
| ---- | ------------------- | ------ | --------------------------- |
| 01   | **Events**          | 8 min  | Capture business facts      |
| 02   | **Commands**        | 8 min  | Represent business requests |
| 03   | **Result Objects**  | 6 min  | Package multiple outputs    |
| 04   | **Aggregates**      | 16 min | Core business logic         |
| 05   | **Entities**        | 12 min | Database mapping            |
| 06   | **Repositories**    | 16 min | Data access layer           |
| 07   | **Event Publisher** | 12 min | Messaging integration       |
| 08   | **Domain Services** | 16 min | Workflow orchestration      |
| 09   | **DTOs**            | 6 min  | API data contracts          |
| 10   | **REST Endpoint**   | 6 min  | HTTP interface              |

**Total:** 106 minutes + 14 minutes buffer = 2 hours

---

### Iteration 2 (7 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Time   | Focus                       |
| ---- | -------------------------------------- | ------ | --------------------------- |
| 01   | **Create the Address Value Object**    | 8 min  | Capture business facts      |
| 02   | **Update the RegisterAttendeeCommand** | 8 min  | Represent business requests |
| 03   | **Update the Attendee Aggregate**      | 6 min  | Package multiple outputs    |
| 04   | **Update the AttendeeRegisteredEvent** | 16 min | Core business logic         |
| 05   | **Update the Persistence Layer**       | 12 min | Database mapping            |
| 06   | **Update the AttendeeService**         | 16 min | Data access layer           |
| 07   | **Update the AttendeeDTO**             | 12 min | Messaging integration       |

**Total:** 106 minutes + 14 minutes buffer = 2 hours

---

### Iteration 3 (7 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Time   | Focus                       |
| ---- | -------------------------------------- | ------ | --------------------------- |
| 01   | **Create the Address Value Object**    | 8 min  | Capture business facts      |
| 02   | **Update the RegisterAttendeeCommand** | 8 min  | Represent business requests |
| 03   | **Update the Attendee Aggregate**      | 6 min  | Package multiple outputs    |
| 04   | **Update the AttendeeRegisteredEvent** | 16 min | Core business logic         |
| 05   | **Update the Persistence Layer**       | 12 min | Database mapping            |
| 06   | **Update the AttendeeService**         | 16 min | Data access layer           |
| 07   | **Update the AttendeeDTO**             | 12 min | Messaging integration       |

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

### 🚀 **Today (Live Session - 2 hours)**

- **Goal:** Working end-to-end system
- **Approach:** Copy code, compile, and understand the basics
- **Questions:** Ask questions at any time!

### 📚 **After Workshop (Self-Study)**

- **Deep-dive materials** explaining the "why" behind what you built
- **Advanced patterns** for production systems
- **Additional iterations** to extend your knowledge

### 🎯 **Future Learning (Optional)**

- **Iteration 2:** Add Value Objects (Address)
- **Iteration 3:** Anti-Corruption Layer for external systems
- **Iteration 4:** Comprehensive testing strategies

---

## Step-by-Step Preview

### Steps 1-3: Foundation (22 minutes)

**Events, Commands, Result Objects**

- **Events:** Capture what happened in the business
- **Commands:** Represent requests for action
- **Result Objects:** Clean way to return multiple values

_These establish the vocabulary of your domain._

### Step 4: The Heart (16 minutes)

**Aggregates**

- **Where business logic lives**
- **Enforces business rules and invariants**
- **Coordinates creating events and domain objects**

_This is the core of Domain-Driven Design._

### Steps 5-6: Persistence (28 minutes)

**Entities and Repositories**

- **Entities:** Map domain objects to database tables
- **Repositories:** Abstract data access behind domain interfaces

_Clean separation between domain model and database concerns._

### Steps 7-8: Integration (28 minutes)

**Event Publisher and Domain Services**

- **Event Publisher:** Send domain events to external systems
- **Domain Services:** Orchestrate complex business workflows

_Hexagonal Architecture in action - adapters for external systems._

### Steps 9-10: API Layer (12 minutes)

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
- **Don't get stuck on theory questions** - save for self-study

### 🆘 **If You Fall Behind:**

- Use the **completed solution files** to catch up
- **Don't panic** - the goal is learning, not perfection
- **Pair with someone** who's keeping up

---

## Pre-Workshop Checklist

### Required Setup (Should be done already)

- [ ] **Java 21+** installed and working
- [ ] **Maven 3.8+** installed and working
- [ ] **IDE** (IntelliJ, VS Code, Eclipse) ready
- [ ] **Workshop repository** cloned
- [ ] **Starter project** compiles: `mvn compile`

## Get Started!
[01-foundations README](01-foundations/README.md)
