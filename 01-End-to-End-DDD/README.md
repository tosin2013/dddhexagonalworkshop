# DDD Hexagonal Workshop - End to End Domain Driven Design

A hands-on workshop teaching Domain-Driven Design (DDD) concepts to Java programmers using Quarkus and the Hexagonal Architecture pattern.

## Workshop Overview

This workshop teaches core DDD concepts by building a conference attendee registration microservice. You'll implement Commands, Events, Aggregates, Domain Services, Repositories, Entities, and Adapters while maintaining clean separation of concerns through the Ports and Adapters pattern.

## Prerequisites

Java 21+
Maven 3.9+
IDE of choice (IntelliJ IDEA, Eclipse, VS Code)
Basic understanding of Java and REST APIs

## Project Structure

The workshop includes Markdown files outlining the the steps and two source code directories:

dddhexagonalworkshop-01/ - Starting project with stubbed classes for hands-on coding
dddhexagonalworkshop-01-solution/ - Complete implementation for reference

The basic project is already built in dddhexagonalworkshop-01. Modify the code as you work through the steps in the workshop. If you get stuck, if you want a hint, or if you just want to see how everything fits together before you begin coding, you can check out the code in dddhexagonalworkshop-01-solution.

## Workshop Steps

### Step 1: Events

**What:** Create AttendeeRegisteredEvent to capture business facts

**Why:** Events represent things that have already happened in your business

**Learn:** Domain Events as immutable facts, event-driven architecture basics

### Step 2: Commands

**What:** Implement RegisterAttendeeCommand to encapsulate business requests

**Why:** Commands represent intentions that can be validated and can fail
**Learn:** Command pattern, input validation, immutable request objects

### Step 3: Result Objects

**What:** Create AttendeeRegistrationResult to package multiple outputs

**Why:** Clean way to return both domain objects and events from operations

**Learn:** Result patterns, avoiding awkward return types

Happy coding! 🚀

## Workshop Files

- [01-Events.md](01-Events.md)
- [02-Commands.md](02-Commands.md)
- [03-ResultObjects.md](03-ResultObjects.md)
- [04-Aggregates.md](04-Aggregates.md)
- [05-Adapters.md](05-Adapters.md)
- [06-Testing.md](06-Testing.md)
- [07-Conclusion.md](07-Conclusion.md)

## Next Steps

### Step 4: Aggregates

**What:** Build the Attendee aggregate with business logic

**Why:** Aggregates are the heart of DDD - they encapsulate business rules and maintain consistency

**Learn:** Aggregate roots, consistency boundaries, business invariants
