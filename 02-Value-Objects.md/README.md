# Step 4: The Heart of DDD (16 minutes)

## Where Your Business Logic Lives

### What We're Building in This Step

The **Attendee Aggregate** - the single most important component in our entire system. This is where all business logic for attendee registration lives, where business rules are enforced, and where domain events are created.

Think of this as the **brain** of your attendee registration system.

---

## Why This Is the Heart of DDD

### The Scattered Logic Problem

In most applications, business logic gets scattered everywhere:

```java
// ❌ Business logic scattered across layers
@RestController
public class AttendeeController {
    public ResponseEntity register(RegisterRequest request) {
        if (request.getEmail() == null) return badRequest(); // Validation in controller
    }
}

@Service
public class AttendeeService {
    public void register(RegisterRequest request) {
        if (attendeeExists(request.getEmail())) throw new Exception(); // Business rule in service
    }
}

@Entity
public class AttendeeEntity {
    @PrePersist
    void validate() {
        if (!email.contains("@")) throw new Exception(); // Validation in entity
    }
}
```

**Problem:** Business logic is everywhere. No one place contains the complete business rules.

### The Aggregate Solution

```java
// ✅ All business logic centralized in one place
public class Attendee {
    public static AttendeeRegistrationResult registerAttendee(String email) {
        // ALL business rules for attendee registration live here
        validateEmailFormat(email);           // Input validation
        checkBusinessRules(email);            // Domain rules
        Attendee attendee = new Attendee(email);
        AttendeeRegisteredEvent event = new AttendeeRegisteredEvent(email);
        return new AttendeeRegistrationResult(attendee, event);
    }
}
```

**Solution:** One place to look for attendee business logic. One place to change it.

---

## What Makes This "The Heart"

### The Core DDD Principle

> **"All business logic for a business concept belongs in its aggregate."**

### What This Means for Attendees

- **Email validation?** → Attendee aggregate
- **Registration rules?** → Attendee aggregate
- **Creating events?** → Attendee aggregate
- **Business invariants?** → Attendee aggregate

### What This Looks Like

```java
// The Attendee aggregate becomes the single source of truth for:
✅ How to create a valid attendee
✅ What rules must be followed during registration
✅ What events should be published when someone registers
✅ How attendees sho
```
