# Domain-Driven Design with Hexagonal Architecture Workshop

Welcome to the **Domain-Driven Design (DDD) with Hexagonal Architecture Workshop**! This hands-on workshop will guide you through implementing core DDD concepts while building a real-world conference attendee registration system using Java and Quarkus.

## 🎯 Workshop Overview

This workshop is for anyone who likes to get their hands on a keyboard as part of the learning process. Your project authors believe that architecture is best learned through practice, and this workshop provides a structured way to apply Domain-Driven Design (DDD) principles in a practical context.

In this introductory workshop, you'll learn to apply Domain-Driven Design principles by building a microservice for managing conference attendee registrations. You'll implement the complete workflow from receiving HTTP requests to persisting data and publishing events, all while maintaining clean architectural boundaries.

### What You'll Build

By the end of this workshop, you will have implemented an attendee registration system that demonstrates:

- **Domain-Driven Design**: Business-focused modeling and implementation
- **Event-Driven Communication**: Asynchronous integration through domain events
- **Hexagonal Architecture**: Creation of loosely coupled application components that can be easily composed; also known as ports and adapters
- **RESTful API Design**: Modern HTTP endpoint implementation
- **Database Integration**: Persistent storage with proper domain/persistence separation

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

## 🚀 About Quarkus

This workshop uses **[Quarkus](https://quarkus.io)**, a modern Java framework designed for cloud-native applications. Quarkus provides several advantages for this workshop:


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
