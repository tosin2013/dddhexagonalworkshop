# Module 1: End to End Domain Driven Design

## 🎯 Overview

In the first module we will build an end to end workflow for conference attendee registration.  The module is designed to introduce DDD concepts by getting your hands on a keyboard and applying Domain-Driven Design (DDD) principles in a practical context.

### What You'll Build

By the end of this module, you will have implemented an attendee registration system that demonstrates:

- **Domain-Driven Design**: Business-focused modeling and implementation
- **Event-Driven Communication**: Asynchronous integration through domain events
- **Hexagonal Architecture**: Creation of loosely coupled application components that can be easily composed; also known as ports and adapters

## 🏗️ Architecture Overview

This module starts with a REST endpoint and implements business logic, persistence, and messaging:

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

## 🗺️ Module Structure

This module is organized into **10 progressive steps**, each building upon the previous one:

| Step   | Concept                                        | What You'll Build            | Key Learning                      |
| ------ | ---------------------------------------------- | ---------------------------- | --------------------------------- |
| **01** | [Events](01-Events.md)                         | `AttendeeRegisteredEvent`    | Domain events as facts            |
| **02** | [Commands](02-Commands.md)                     | `RegisterAttendeeCommand`    | Capturing business intentions     |
| **03** | [Return Values](03-Combining-Return-Values.md) | `AttendeeRegistrationResult` | Clean method signatures           |
| **04** | [Aggregates](04-Aggregates.md)                 | `Attendee`                   | Core business logic encapsulation |
| **05** | [Entities](05-Entities.md)                     | `AttendeeEntity`             | Persistence layer separation      |
| **06** | [Repositories](06-Repositories.md)             | `AttendeeRepository`         | Data access abstraction           |
| **07** | [Outbound Adapters](07-Outbound-Adaptes.md)    | `AttendeeEventPublisher`     | External system integration       |
| **08** | [Domain Services](08-Domain-Services.md)       | `AttendeeService`            | Workflow orchestration            |
| **09** | [DTOs](09-Data-Transfer-Objects.md)            | `AttendeeDTO`                | External representation           |
| **10** | [Inbound Adapters](10-Inbound-Adapters.md)     | `AttendeeEndpoint`           | HTTP interface completion         |

### Learning Approach

Each step follows a consistent pattern:

- **🎯 TL;DR**: a quick implementation reference with no explaination
- **📖 Concept Explanation**: Why this pattern matters
- **💻 Hands-On Implementation**: Code with detailed explanations
- **🧪 Testing Guidance**: Verify your implementation
- **🤔 Other Considerations**: Production concerns and alternatives

If you get stuck, do not hesitate to ask for help!

## 🎓 Learning Objectives

At the end of this module completing this module, you will:

### Have Touched Many DDD Fundamentals

- Distinguish between commands and events
- Identify proper aggregate boundaries
- Implement domain services for complex workflows
- Apply the repository pattern correctly

### Use a Hexagonal Architecture

- Separate business logic from technical concerns
- Create adapters for external system integration
- Design clean interfaces between layers
- Maintain testable, technology-independent code

## 🆘 Getting Help

If you encounter issues:

1. Check the code in **model-01-soltuion** 
2. Verify your code matches the provided examples exactly
3. Look for error messages in the console output

## 🎉 Ready to Begin?

Great! Start your DDD journey with [**Step 1: Events**](01-Events.md) 

Happy coding! 🚀
