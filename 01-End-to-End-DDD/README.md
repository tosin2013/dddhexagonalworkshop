# Domain-Driven Design with Hexagonal Architecture Workshop

Welcome to the **Domain-Driven Design (DDD) with Hexagonal Architecture Workshop**! This hands-on workshop will guide you through implementing core DDD concepts while building a real-world conference attendee registration system using Java and Quarkus.

## 🎯 Workshop Overview

This workshop is for anyone who likes to get their hands on a keyboard as part of the learning process.  Your project authors believe that architecture is best learned through practice, and this workshop provides a structured way to apply Domain-Driven Design (DDD) principles in a practical context.

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

### Why Quarkus?

- **⚡ Supersonic, Subatomic Java**: Incredibly fast startup times and low memory usage
- **🔧 Developer Experience**: Live reload during development - see changes instantly
- **🐳 Container First**: Built for Kubernetes and cloud deployment from the ground up
- **📦 Unified Configuration**: Single configuration model for all extensions
- **🎯 Standards-Based**: Built on proven standards like JAX-RS, CDI, and JPA

Most importantly, Quarkus gets out of your way, allowing you to focus on your code.

Your workshop authors work for Red Hat, the company behind Quarkus, but we believe that Quarkus is the best choice because it allows you to focus on implementing Domain-Driven Design (DDD) concepts without worrying about boilerplate code or complex configurations.

### Workshop-Specific Benefits

**Dev Mode Magic**: Quarkus automatically starts and manages external dependencies:
```bash
mvn quarkus:dev
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

**Real-World Relevance**: Learn patterns you'll use in production:
- Reactive messaging with Kafka
- Database transactions with Hibernate/Panache
- RESTful API development with JAX-RS
- Health checks and metrics
- Native compilation readiness

## 📋 Prerequisites

### Required Knowledge
- **Java 21+**: Comfortable with modern Java features (records, switch expressions)
- **Basic OOP**: Understanding of classes, interfaces, and inheritance
- **Web Concepts**: HTTP methods, JSON, REST APIs
- **Database Basics**: SQL fundamentals and persistence concepts

### Development Environment
- **Java 17 or higher** installed
- **Maven 3.8+** for dependency management
- **IDE** of choice (IntelliJ IDEA, VS Code, Eclipse)
- **Docker** (optional - for running external services manually)

### No Prior Experience Needed
- Domain-Driven Design concepts
- Hexagonal Architecture
- Quarkus framework
- Event-driven systems
- Kafka or messaging systems

## 🗺️ Workshop Structure

This workshop is organized into **10 progressive steps**, each building upon the previous one:

| Step | Concept | What You'll Build | Key Learning |
|------|---------|-------------------|--------------|
| **01** | [Events](01-Events.md) | `AttendeeRegisteredEvent` | Domain events as facts |
| **02** | [Commands](02-Commands.md) | `RegisterAttendeeCommand` | Capturing business intentions |
| **03** | [Return Values](03-Combining-Return-Values.md) | `AttendeeRegistrationResult` | Clean method signatures |
| **04** | [Aggregates](04-Aggregates.md) | `Attendee` | Core business logic encapsulation |
| **05** | [Entities](05-Entities.md) | `AttendeeEntity` | Persistence layer separation |
| **06** | [Repositories](06-Repositories.md) | `AttendeeRepository` | Data access abstraction |
| **07** | [Outbound Adapters](07-Outbound-Adaptes.md) | `AttendeeEventPublisher` | External system integration |
| **08** | [Domain Services](08-Domain-Services.md) | `AttendeeService` | Workflow orchestration |
| **09** | [DTOs](09-Data-Transfer-Objects.md) | `AttendeeDTO` | External representation |
| **10** | [Inbound Adapters](10-Inbound-Adapters.md) | `AttendeeEndpoint` | HTTP interface completion |

### Learning Approach

Each step follows a consistent pattern:
- **🎯 TL;DR**: Quick implementation reference
- **📖 Concept Explanation**: Why this pattern matters
- **💻 Hands-On Implementation**: Code with detailed explanations
- **🧪 Testing Guidance**: Verify your implementation
- **🤔 Real-World Considerations**: Production concerns and alternatives

If you get stuck, do not hesitate to ask for help!

## 🚦 Getting Started

### 1. Clone the Workshop Repository
```bash
git clone [workshop-repository-url]
cd ddd-hexagonal-workshop
```

### 2. Verify Your Environment
```bash
java --version    # Should show Java 17+
mvn --version     # Should show Maven 3.8+
```

### 3. Start the Development Environment
```bash
mvn quarkus:dev
```
This starts Quarkus in development mode with live reload enabled.

### 4. Verify the Setup
Open your browser to `http://localhost:8080` - you should see the Quarkus welcome page.

### 5. Begin the Workshop
Start with [Step 1: Events](01-Events.md) and work through each step sequentially.

## 📁 Project Structure

The workshop uses a clean, DDD-aligned package structure:

```
src/main/java/dddhexagonalworkshop/conference/attendees/
├── domain/                          # Pure business logic
│   ├── aggregates/                  # Domain aggregates
│   │   └── Attendee.java
│   ├── events/                      # Domain events
│   │   └── AttendeeRegisteredEvent.java
│   └── services/                    # Domain services & commands
│       ├── AttendeeService.java
│       ├── RegisterAttendeeCommand.java
│       └── AttendeeRegistrationResult.java
├── infrastructure/                  # External integrations
│   ├── AttendeeEndpoint.java       # REST adapter
│   ├── AttendeeDTO.java            # Data transfer objects
│   └── AttendeeEventPublisher.java  # Kafka adapter
└── persistence/                     # Database layer
    ├── AttendeeEntity.java         # JPA entity
    └── AttendeeRepository.java     # Data access
```

This structure reflects DDD's emphasis on organizing code by **business capability** rather than technical layers.

## 🎓 Learning Objectives

By completing this workshop, you will:

### Understand DDD Fundamentals
- Distinguish between commands and events
- Identify proper aggregate boundaries
- Implement domain services for complex workflows
- Apply the repository pattern correctly

### Master Hexagonal Architecture
- Separate business logic from technical concerns
- Create adapters for external system integration
- Design clean interfaces between layers
- Maintain testable, technology-independent code

### Build Production-Ready Systems
- Handle errors gracefully across layers
- Implement proper transaction boundaries
- Design APIs following REST principles
- Structure code for maintainability and evolution

### Gain Practical Experience
- Work with modern Java frameworks (Quarkus)
- Integrate with real external systems (Kafka, PostgreSQL)
- Write tests at the appropriate levels
- Apply patterns you'll use in professional development

## 🤝 Workshop Philosophy

This workshop emphasizes **learning by doing**. Each concept is introduced with:
- **Real-world context** explaining why it matters
- **Practical implementation** with complete working code
- **Common pitfalls** and how to avoid them
- **Testing strategies** to ensure correctness
- **Evolution considerations** for long-term maintenance

## 💡 Tips for Success

1. **Follow the sequence**: Each step builds on previous ones - don't skip ahead
2. **Read the explanations**: Understanding the "why" is as important as the "how"
3. **Experiment**: Try variations and see what breaks (and why)
4. **Test frequently**: Run tests after each step to catch issues early
5. **Ask questions**: The concepts are meant to be discussed and debated

## 🆘 Getting Help

If you encounter issues:
1. Check the **Testing Your Implementation** section in each step
2. Verify your code matches the provided examples exactly
3. Ensure Quarkus dev mode is running (`mvn quarkus:dev`)
4. Look for error messages in the console output

## 🎉 Ready to Begin?

Great! Start your DDD journey with [**Step 1: Events**](01-Events.md) and begin building your understanding of domain-driven design through practical implementation.

Remember: the goal isn't just to complete the code, but to understand the principles that will help you build better software systems throughout your career.

Happy coding! 🚀