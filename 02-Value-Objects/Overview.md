# Module 2: Value Objects

## 🎯 Overview

In the first module we built an end to end workflow for conference attendee registration.  The module is designed to introduce the DDD concept of Value Objects by extending the original application.

### What You'll Build

By the end of this module, you will have updated the application to use a Value Object for the attendee's address.


- **Value Objects**: a fundamental building block of DDD 

## 📚 Core DDD Concepts Covered

### 🎪 **Value Objects**

The heart of DDD - business entities that encapsulate logic and maintain consistency within their boundaries.

### 🎪 **Aggregates**

The heart of DDD - business entities that encapsulate logic and maintain consistency within their boundaries.

### 📋 **Events & Commands**

- **Events**: Record facts that have already occurred (immutable) and most importantly _what the business cares about_.
- **Commands**: Represent intentions to change state (can fail)

### 📦 **Entities**

Model your domain with appropriate object types that reflect business concepts.

### 🗃️ **Repositories**

Provide a collection-like interface for accessing and persisting aggregates, abstracting database details.


## 🗺️ Module Structure

This module is organized into **10 progressive steps**, each building upon the previous one:

| Step   | Concept                                        | What You'll Build            | Key Learning                      |
| ------ | ---------------------------------------------- | ---------------------------- | --------------------------------- |
| **01** | [Value Objects](01-Value-Objects.md)                         | `Address`    | The role of value objects            |
| **02** | [Commands](02-Update-the-Command.md)                     | `RegisterAttendeeCommand`    | Capturing business intentions     |
| **03** | [Aggregates](03-Update-the-Aggregate.md) | `Attendee` | Aggregate design           |
| **04** | [Events](04-Update-the-Event.md)                 | `AttendeeRegisteredEvent`                   | Tracking system events |
| **05** | [Update the Persistence Layer](05-Update-the-Persistence.md)                     | `AttendeeEntity`, `AddressEntity`            | Persistence layer separation      |
| **06** | [Data Transfer Objects](06-Update-the-DTO.md)             | `AttendeeDTO`         | Data transfer abstraction           |
| **07** | [Application Services](07-Update-the-Service.md)    | `AttendeeService`     | Domain functionality       |

### Learning Approach

Each step follows a consistent pattern:

- **🎯 TL;DR**: a quick implementation reference with no explaination
- **📖 Concept Explanation**: Why this pattern matters
- **💻 Hands-On Implementation**: Code with detailed explanations

If you get stuck, do not hesitate to ask for help!

## 🎓 Learning Objectives

At the end of this module completing this module, you will:

### Added Value Objects to DDD Fundamentals

- Distinguish between Aggregates and Value Objects
- Persistence strategies for dependent objects
- Sharing data between bounded contexts

## 🆘 Getting Help

If you encounter issues:

1. Check the code in **model-01-soltuion** 
2. Verify your code matches the provided examples exactly
3. Look for error messages in the console output

## 🎉 Ready to Begin?

Great! Start your DDD journey with [**Step 1: Value Objects**](01-Value-Objects.md) 

Happy coding! 🚀
