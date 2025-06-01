# Step 2: Update the RegisterAttendeeCommand

## Overview

In this step, we'll update the `RegisterAttendeeCommand` to include the new address field along with first and last name fields. This demonstrates how commands evolve to capture new business requirements while maintaining the command pattern.

## Understanding Commands in DDD

Commands represent the intent to change the state of the system. They:

- Capture user intentions
- Contain all data needed to perform an operation
- Are immutable once created
- Follow the Command Pattern

## Implementation

Update the `RegisterAttendeeCommand` to include the enhanced attendee information:

```java
package dddhexagonalworkshop.conference.attendees.domain.services;

import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

public record RegisterAttendeeCommand(String email, String firstName, String lastName, Address address) {
}
```

## Key Changes

1. **Added firstName and lastName fields**: Instead of storing a single name, we now separate first and last names for better data management
2. **Added Address value object**: The command now includes the complete address information encapsulated in our Address value object
3. **Maintained immutability**: Using a Java record ensures the command remains immutable

## Benefits of This Approach

- **Rich Domain Model**: The command now captures more meaningful business data
- **Type Safety**: Using the Address value object provides compile-time safety
- **Validation**: Address validation happens automatically when the Address is created
- **Evolution**: Shows how commands can evolve as business requirements change

## Next Step

Continue to [Step 3: Update the Attendee Aggregate](step3-update-attendee.md)
