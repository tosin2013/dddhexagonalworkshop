# Steps 1-2: Building Blocks

## The Building Blocks of Domain Driven Design

### What We're Building in This Module

The basic "vocabulary" that your domain will use to communicate:

- **Events:** Facts about what happened in your business
- **Commands:** Requests for actions you want to take
- **Result Objects:** Clean packages for returning multiple values

Think of this as creating the **language** your domain speaks.

---

## Why We Start Here

### The Communication Problem

In most applications, business concepts get lost in technical noise:

```java
// ❌ What business concept does this represent?
public String processUser(Map<String, Object> data, HttpRequest request) {
    // Is this capturing a business fact or requesting an action?
    // What actually happened here?
}
```

### Our Solution: Domain Language

```java
// ✅ Crystal clear business intent
AttendeeRegisteredEvent event = new AttendeeRegisteredEvent("john@example.com");
RegisterAttendeeCommand command = new RegisterAttendeeCommand("john@example.com");
AttendeeRegistrationResult result = attendee.register(command);
```

**The difference:** Anyone can read this code and understand the business concepts.

---

## The Foundation Pattern

### How These Work Together

```
1. Command Request  →  2. Business Logic  →  3. Result Package
RegisterAttendeeCommand  →  Attendee.register()  →  AttendeeRegistrationResult
     (Intent)                    (Action)              (Outcome)
        ↓                          ↓                     ↓
   "I want to register"    "Validate and create"    "Attendee + Event"
```

### Real-World Flow

1. **Web request comes in** → Convert to `RegisterAttendeeCommand`
2. **Domain processes it** → Creates `Attendee` and `AttendeeRegisteredEvent`
3. **Return both cleanly** → Packaged in `AttendeeRegistrationResult`
4. **Service coordinates** → Saves attendee, publishes event

---

## Module Overview

### Step 1: Events (8 minutes)

**What:** Capture business facts that have already happened
**Example:** `AttendeeRegisteredEvent` - "John registered for the conference"
**Why:** Other systems need to react to business events

### Step 2: Commands (8 minutes)

**What:** Represent requests for business actions
**Example:** `RegisterAttendeeCommand` - "Please register John for the conference"
**Why:** Clear intent, can be validated, can fail gracefully

### Step 3: Result Objects (6 minutes)

**What:** Package multiple outputs from business operations
**Example:** `AttendeeRegistrationResult` - Contains both the attendee and the event
**Why:** Avoid awkward return types, clear what operations produce

---

## Learning Strategy for This Module

### 🚀 **Live Session Focus**

- **Get the code compiling** quickly
- **Understand basic purpose** of each component
- **See how they connect** to each other

### 📚 **Self-Study Deep Dives Available**

- **Events vs Commands:** Detailed comparison with examples
- **Domain modeling:** How to identify events and commands in your business
- **Result patterns:** Alternative approaches and when to use them
- **Immutability:** Why these objects should never change

---

## Success Criteria for Foundation

### By End of Step 3, You'll Have:

- [x] `AttendeeRegisteredEvent` that captures registration facts
- [x] `RegisterAttendeeCommand` that represents registration requests
- [x] `AttendeeRegistrationResult` that packages outputs cleanly
- [x] **All code compiles** and basic understanding of purpose
- [x] **Foundation vocabulary** for the rest of the workshop

### What You're Building Toward:

```java
// This is where we're heading (you'll build this in Step 4):
AttendeeRegistrationResult result = Attendee.registerAttendee(command.email());
//                           ↑                    ↑              ↑
//                    Result Object         Aggregate        Command
//                  (What we return)    (Business Logic)  (What we receive)
```

---

## Common Questions (Save for Self-Study!)

### "Why separate events and commands?"

**Quick answer:** Commands can fail, events are facts that already happened.
**Deep dive:** Available in self-study materials with examples.

### "Why not just return the attendee directly?"

**Quick answer:** Business operations often need to return multiple things.
**Deep dive:** Result patterns explained in self-study materials.

### "Are these DDD-specific patterns?"

**Quick answer:** Commands and results are general patterns; events are core to DDD.
**Deep dive:** Pattern evolution and alternatives in self-study materials.

---

## Module Progression

### Step 1: Events → "What happened?"

- Create immutable facts about business occurrences
- Foundation for event-driven architecture
- **Time:** 8 minutes

### Step 2: Commands → "What do we want to happen?"

- Create requests for business actions
- Input validation and clear intent
- **Time:** 8 minutes

### Step 3: Result Objects → "How do we return multiple things cleanly?"

- Package complex operation outputs
- Avoid awkward return types
- **Time:** 6 minutes

**Total Foundation Time:** 22 minutes

---

## Ready to Start?

### Our First Component: Events

_"We start with events because they represent the most important thing in any business system - the facts that matter. When someone registers for our conference, what fact do we want to capture and announce to the world?"_

### What You'll Create:

```java
public record AttendeeRegisteredEvent(String email) {
}
```

### Why This Matters:

This simple line of code represents a **business fact** that other systems can react to. Welcome emails, capacity updates, badge generation - all triggered by this one clear signal.

---

## Facilitator Notes

### Opening This Module (2 minutes):

> "Alright everyone, we're starting with the foundation - Steps 1 through 3. These next 22 minutes we're building the basic vocabulary your domain will use to communicate. Think of events as facts, commands as requests, and result objects as clean packages for complex outputs.
>
> Don't worry about understanding every nuance - we're building the language first, then we'll use it to build the actual business logic. Ready? Let's create our first domain event..."

### Key Messages for This Module:

1. **"These are the words your domain uses to communicate"**
2. **"Events are facts, commands are requests"**
3. **"Result objects keep complex returns clean"**
4. **"This foundation makes everything else possible"**

### Transition to Step 4:

> "Perfect! You now have the vocabulary your domain needs. You can capture facts with events, make requests with commands, and return complex results cleanly. Now let's build the business logic that uses this vocabulary - time for aggregates!"

### If Running Behind:

- Skip detailed explanations in Steps 1-2
- Focus purely on "copy this code, paste it, compile"
- Save all explanation for Step 3 transition

### If Running Ahead:

- Show quick examples of how these connect
- Preview how they'll be used in upcoming steps
- Take 1-2 quick questions about the concepts
