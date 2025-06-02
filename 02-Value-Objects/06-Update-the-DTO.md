Upda# Step 6: Update the AttendeeDTO

## tl;dr

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

public record AttendeeDTO(String email, String fullName) {
}
```

## Overview

In this step, we'll update the `AttendeeDTO` that is used to transfer data between the service and the controller. This demonstrates how Data Transfer Objects (DTOs) provide a stable interface for external communication while hiding internal domain complexity.

## Understanding DTOs in Hexagonal Architecture

DTOs serve as:

- **Anti-corruption Layer**: Protect domain models from external influence
- **Stable Interface**: Provide consistent API contracts regardless of internal changes
- **Data Shape Control**: Expose only the information needed by API consumers
- **Serialization Boundary**: Optimized for JSON/XML serialization

## Current Implementation

The current `AttendeeDTO` focuses on the essential information needed for API responses:

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

public record AttendeeDTO(String email, String fullName) {
}
```

## Design Rationale

### What We Include

- **Email**: The primary identifier for the attendee
- **Full Name**: The computed full name from first and last names

### What We Don't Include

- **Address**: Sensitive information that may not be needed for all API responses
- **Individual Name Components**: Clients typically need the full name rather than separate parts

## Strategic Considerations

### Why Not Include Address?

1. **Privacy**: Address information is sensitive and should only be exposed when necessary
2. **Performance**: Reduces payload size for list operations
3. **Flexibility**: Different endpoints can return different DTOs based on needs
4. **Security**: Principle of least privilege - only expose what's needed

### Future Extensions

If different endpoints need different information, you could create:

- `AttendeeDetailDTO` - includes address for detailed views
- `AttendeeListDTO` - minimal info for list operations
- `AttendeePublicDTO` - public-safe information only

## Alternative Implementation with Address

If you do need to include address information, you could create:

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

import dddhexagonalworkshop.conference.attendees.domain.valueobjects.Address;

public record AttendeeDTO(String email, String fullName, Address address) {
}
```

## Benefits of This Approach

1. **Clean Separation**: Domain models can evolve independently of API contracts
2. **Focused Information**: Only includes data relevant to API consumers
3. **Type Safety**: Compile-time guarantees about data structure
4. **Immutability**: Records ensure DTOs can't be modified after creation
5. **Performance**: Lightweight objects optimized for serialization

## Integration with JSON APIs

The DTO will automatically serialize to JSON like:

```json
{
  "email": "john.doe@example.com",
  "fullName": "John Doe"
}
```

## Next Step

Continue to [Step 7: Update the AttendeeService](step7-update-service.md)
