# Steps 5-6: Persistence (28 minutes)

## Bridging Domain and Database

### What We're Building in This Module

The **persistence layer** that saves our domain objects to the database while keeping our business logic completely separate from database concerns:

- **Entities:** Map domain data to database tables
- **Repositories:** Provide domain-friendly interfaces for data access

Think of this as building a **clean bridge** between your pure domain model and the messy reality of databases.

---

## Why Persistence Separation Matters

### The Domain Pollution Problem

Most applications mix domain logic with database concerns:

```java
// ❌ Domain aggregate polluted with database annotations
@Entity @Table(name = "attendees")
public class Attendee {
    @Id @GeneratedValue
    private Long id;                    // Database concern in domain!

    @Column(name = "email", length = 255)
    private String email;               // Database constraints in domain!

    public static AttendeeRegistrationResult registerAttendee(String email) {
        // Business logic mixed with JPA annotations
        // Can't test without database
        // Tied to specific database technology
    }
}
```

**Problems:**

- Domain model knows about database details
- Can't test business logic without database
- Changing database requires changing domain
- Business logic mixed with technical concerns

### The Clean Separation Solution

```java
// ✅ Pure domain aggregate - no database knowledge
public class Attendee {
    private final String email;  // No annotations!

    public static AttendeeRegistrationResult registerAttendee(String email) {
        // Pure business logic
        // Testable without database
        // Technology independent
    }
}

// ✅ Separate entity for database mapping
@Entity @Table(name = "attendee")
public class AttendeeEntity {
    @Id @GeneratedValue
    private Long id;
    private String email;
    // No business logic - just data mapping
}

// ✅ Repository bridges between them
public class AttendeeRepository {
    public void persist(Attendee aggregate) {
        AttendeeEntity entity = fromAggregate(aggregate);  // Convert
        persist(entity);                                   // Save
    }
}
```

**Benefits:**

- Domain stays pure and testable
- Database can change without affecting business logic
- Clear separation of concerns
- Easy to understand and maintain

---

## The Two-Layer Persistence Pattern

### How Domain and Database Stay Separate

```
Domain Layer:           Persistence Layer:
┌─────────────────┐    ┌──────────────────────┐
│ Attendee        │    │ AttendeeEntity       │
│ (Business       │◄──►│ (Database           │
│  Logic)         │    │  Mapping)           │
└─────────────────┘    └──────────────────────┘
        ▲                        ▲
        │                        │
┌─────────────────┐    ┌──────────────────────┐
│ AttendeeService │    │ AttendeeRepository   │
│ (Uses Domain)   │    │ (Converts & Saves)   │
└─────────────────┘    └──────────────────────┘
```

### The Conversion Flow

1. **Domain Service** creates `Attendee` aggregate (business logic)
2. **Repository** converts `Attendee` → `AttendeeEntity` (mapping)
3. **JPA/Hibernate** saves `AttendeeEntity` to database (persistence)
4. **Loading reverses:** Database → `AttendeeEntity` → `Attendee`

---

## Module Overview

### Step 5: Entities (12 minutes)

**What:** Database mapping objects with JPA annotations
**Purpose:** Handle all database-specific concerns
**Focus:** Pure data mapping, no business logic

### Step 6: Repositories (16 minutes)

**What:** Domain-friendly interfaces for data access
**Purpose:** Convert between domain aggregates and database entities  
**Focus:** Clean abstraction over database operations

---

## Key Concepts We'll Experience

### Entity Responsibilities

- **Database mapping:** JPA annotations, table structure
- **Technical identity:** Database IDs for performance
- **Framework compatibility:** What JPA/Hibernate needs
- **Data conversion:** Getters/setters for ORM frameworks

### Repository Responsibilities

- **Domain interface:** Methods named for business operations
- **Aggregate conversion:** Domain objects ↔ Database entities
- **Query abstraction:** Hide SQL and database details
- **Transaction support:** Work within service transaction boundaries

### What Each Layer DOESN'T Do

```java
// ✅ Domain Aggregate - NO database concerns
public class Attendee {
    // ❌ No @Entity, @Id, @Column annotations
    // ❌ No database IDs or technical fields
    // ✅ Pure business logic and validation
}

// ✅ Database Entity - NO business logic
@Entity
public class AttendeeEntity {
    // ✅ Database annotations and mapping
    // ✅ Technical fields like generated IDs
    // ❌ No business methods or validation
}
```

---

## The Repository Pattern Deep Dive

### Not Your Typical DAO

```java
// ❌ Traditional DAO - database focused
public class AttendeeDAO {
    AttendeeEntity findById(Long id);           // Database concept
    List<AttendeeEntity> findAll();            // Returns entities
    void insert(AttendeeEntity entity);        // Database operation
}

// ✅ DDD Repository - domain focused
public class AttendeeRepository {
    Optional<Attendee> findByEmail(String email);  // Business concept
    List<Attendee> findRegisteredAttendees();      // Returns aggregates
    void persist(Attendee attendee);              // Domain operation
}
```

### The Magic: Invisible Conversion

```java
// From the domain service perspective:
AttendeeRegistrationResult result = Attendee.registerAttendee(email);
attendeeRepository.persist(result.attendee());  // Looks like saving domain object

// What actually happens inside repository:
public void persist(Attendee aggregate) {
    AttendeeEntity entity = fromAggregate(aggregate);  // Convert to entity
    panacheRepository.persist(entity);                 // Save to database
    // Domain service never knows about entities!
}
```

---

## Learning Strategy for This Module

### 🚀 **Live Session Focus (28 minutes)**

- **Step 5 (12 min):** Create entity with JPA mapping, see separation
- **Step 6 (16 min):** Build repository with conversion logic
- **Understand the bridge pattern** between domain and database
- **See clean separation** in action

### 📚 **Self-Study Deep Dives Available**

- **Entity design patterns:** Mapping strategies, relationships, performance
- **Repository patterns:** Specifications, CQRS, complex queries
- **Testing strategies:** Unit testing repositories, integration testing
- **Advanced mapping:** Value objects, embedded entities, inheritance
- **Performance considerations:** Lazy loading, caching, optimization

---

## Why This Module Takes 28 Minutes

### Persistence is Complex

- **Two components:** Entity (12 min) + Repository (16 min)
- **New concepts:** JPA annotations, ORM patterns, conversion logic
- **Integration complexity:** How domain and database connect
- **Critical pattern:** Get this wrong and your domain becomes polluted

### Time Breakdown

- **Entity (12 min):** JPA mapping, annotation explanation, database concerns
- **Repository (16 min):** Domain interface, conversion methods, abstraction concepts

---

## Success Criteria for This Module

### By End of Step 6, You'll Have:

- [x] `AttendeeEntity` that maps domain data to database tables
- [x] `AttendeeRepository` that converts between aggregates and entities
- [x] **Clean separation** between domain logic and database concerns
- [x] **Working persistence** that saves attendees to PostgreSQL
- [x] **Understanding** of how to keep domain models pure

### What You're Building Toward:

```java
// This complete flow will work after this module:
RegisterAttendeeCommand command = new RegisterAttendeeCommand("john@example.com");
AttendeeRegistrationResult result = Attendee.registerAttendee(command.email());

// Domain service can save aggregates directly
attendeeRepository.persist(result.attendee());

// And retrieve them as aggregates
Optional<Attendee> retrieved = attendeeRepository.findByEmail("john@example.com");
```

---

## Common Persistence Anti-Patterns (Avoid These!)

### ❌ **Active Record Pattern**

```java
// Don't do this - domain object knows about persistence
public class Attendee extends ActiveRecord {
    public void save() {                    // Database concern in domain!
        super.save();                       // Tied to persistence framework
    }

    public static List<Attendee> findAll() { // Query logic in domain!
        return super.findAll();             // Can't test without database
    }
}
```

### ✅ **Repository Pattern**

```java
// Do this - clean separation
public class Attendee {
    // Pure domain logic, no persistence knowledge
}

public class AttendeeRepository {
    // All persistence concerns isolated here
    public void persist(Attendee aggregate) { ... }
    public Optional<Attendee> findByEmail(String email) { ... }
}
```

### ❌ **Leaky Abstractions**

```java
// Don't do this - domain service knows about entities
@Service
public class AttendeeService {
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand cmd) {
        AttendeeEntity entity = new AttendeeEntity(cmd.email());  // Domain knows about entities!
        entityManager.persist(entity);                            // Domain knows about JPA!
        return new AttendeeDTO(entity.getEmail());
    }
}
```

### ✅ **Clean Abstraction**

```java
// Do this - domain service only knows about domain
@Service
public class AttendeeService {
    public AttendeeDTO registerAttendee(RegisterAttendeeCommand cmd) {
        AttendeeRegistrationResult result = Attendee.registerAttendee(cmd.email());
        attendeeRepository.persist(result.attendee());            // Domain interface!
        return new AttendeeDTO(result.attendee().getEmail());
    }
}
```

---

## The Technology Stack

### What We're Using

- **JPA/Hibernate:** Object-relational mapping
- **Quarkus Panache:** Simplified repository base classes
- **PostgreSQL:** Database (auto-started by Quarkus dev mode)
- **Jakarta Persistence:** Modern JPA annotations

### What You Don't Need to Know

- **SQL:** Repository abstracts database queries
- **Database schema:** Entities define the structure
- **Connection management:** Quarkus handles automatically
- **Transaction management:** Framework manages for us

---

## Ready for Persistence?

### What We're About to Build

The bridge between your pure domain model and the database:

1. **AttendeeEntity:** Knows how to map attendee data to database tables
2. **AttendeeRepository:** Knows how to convert between domain and database

### Why This Matters

After this module, your domain aggregates can be saved and retrieved from the database, but your business logic stays completely independent of database technology.

**Your domain stays pure, your data gets persisted.**

---

## Facilitator Notes

### Opening This Module (2 minutes):

> "Alright everyone, Steps 5 and 6 - the persistence layer. 28 minutes total. We're building the bridge between our pure domain model and the database.
>
> The key insight here is separation - our Attendee aggregate stays pure business logic, and we create separate objects that know how to talk to the database. This keeps our domain testable and technology-independent.
>
> Step 5 is entities - database mapping. Step 6 is repositories - the bridge between domain and database. Ready? Let's keep our domain pure while making it persistent..."

### Key Messages for This Module:

1. **"Keep domain pure - separate business logic from database concerns"**
2. **"Entities handle database mapping, repositories handle conversion"**
3. **"This is how you get persistence without polluting your domain"**
4. **"One aggregates, one entity, one repository - clean separation"**

### Managing Entity Complexity:

- **Focus on separation:** "This handles database stuff so domain doesn't have to"
- **Don't explain every annotation:** "JPA needs these, focus on the pattern"
- **Emphasize the conversion:** "Repository converts between domain and database"

### Managing Repository Complexity:

- **Show the bridge pattern:** "Takes domain objects, converts to entities"
- **Emphasize abstraction:** "Domain service never sees entities"
- **Demo the conversion:** "fromAggregate and toAggregate methods"

### Transition to Step 7:

> "Perfect! Now we have persistence working. Our domain aggregates can be saved to the database while staying completely pure. But remember - our aggregates also create events that need to be published to other systems. Time to build our outbound adapter for messaging..."

### If Running Behind:

- **Skip detailed JPA explanation:** "These annotations map to database"
- **Focus on conversion pattern:** "Repository converts domain to database"
- **Use emergency shortcuts:** Pre-written code if needed

### If Running Ahead:

- **Show database working:** Quick demo of data being saved
- **Explain more annotations:** Walk through JPA mapping details
- **Preview integration:** Show how this connects to domain services
