# Iteration 02: Adding Value Objects

## Overview

In this iteration we will enhance the `Attendee` model by adding an address field. This will allow us to store more detailed information about each attendee using **Value Objects** - a core Domain Driven Design concept.

We will also use the `Hexagonal Architecture`, or `Ports and Adapters` pattern to integrate with external systems, ensuring a clean separation of concerns.

## DDD Concepts Covered

- **Value Objects**: Objects that describe the state of something else, equal based on their value rather than identity
- **Hexagonal Architecture**: Maintaining clean boundaries between domain, persistence, and infrastructure layers

## Technology Stack

**Quarkus** (https://quarkus.io) is a modern Java framework designed for building cloud-native applications. It provides a set of tools and libraries that make it easy to develop, test, and deploy applications. In this workshop, we will leverage Quarkus to implement our DDD concepts and build a RESTful API for registering attendees.

The project uses Quarkus features including:

- Built-in support for REST endpoints
- JSON serialization
- Database access
- `Dev Mode` that automatically spins up external dependencies like Kafka and PostgreSQL

## Project Structure

The basic project structure is already set up for you:

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
│       │   │   └── AttendeeService.java
│       │   │   └── RegisterAttendeeCommand.java
│       │   └── valueobjects
│       │       └── Address.java
│       ├── infrastructure
│       │   ├── AttendeeEndpoint.java
│       │   ├── AttendeeDTO.java
│       │   └── AttendeeEventPublisher.java
│       └── persistence
│           ├── AttendeeEntity.java
│           └── AttendeeRepository.java
```

## Workshop Steps

This iteration is divided into the following steps:

1. **[Step 1: Create the Address Value Object](step1-address-value-object.md)**
2. **[Step 2: Update the RegisterAttendeeCommand](step2-update-command.md)**
3. **[Step 3: Update the Attendee Aggregate](step3-update-attendee.md)**
4. **[Step 4: Update the AttendeeRegisteredEvent](step4-update-event.md)**
5. **[Step 5: Update the Persistence Layer](step5-update-persistence.md)**
6. **[Step 6: Update the AttendeeDTO](step6-update-dto.md)**
7. **[Step 7: Update the AttendeeService](step7-update-service.md)**

## How to Use This Workshop

As you progress through the workshop, you will fill in the missing pieces of code in the appropriate packages. The workshop authors have stubbed out the classes so that you can focus on the Domain Driven Design concepts as much as possible and Java and framework concepts as little as possible.

You can:

- Type in the code line by line
- Copy and paste the code provided into your IDE
- Combine both approaches as you see fit

The goal is to understand the concepts and how they fit together in a DDD context.

## Expected Outcome

By the end of this iteration, you'll have:

- A solid understanding of Value Objects in DDD
- An enhanced Attendee model with proper address encapsulation
- Experience with evolving domain models while maintaining clean architecture
- A working application that demonstrates hexagonal architecture principles

Let's get coding!
