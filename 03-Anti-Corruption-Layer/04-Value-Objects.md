# Step 4: Update Domain Value Objects

## Overview

In this step, we need to create new value objects that our Anti-Corruption Layer translator references: `MealPreference` and `TShirtSize`. These value objects represent domain concepts that are distinct from the external system's terminology.

## Understanding Domain Value Objects

Value objects in our domain:
- **Represent** domain concepts using domain language
- **Encapsulate** business rules and validation
- **Remain** independent of external system terminology
- **Provide** type safety and clarity
- **Enable** rich domain modeling

## Value Objects to Create

Based on our translator implementation, we need:
1. `MealPreference` - represents dietary preferences in domain terms
2. `TShirtSize` - represents t-shirt sizes available in our domain

## Implementation

### MealPreference.java

Create the `MealPreference` value object in the `valueobjects` package:

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

/**
 * Represents meal preferences for conference attendees.
 * Uses domain-specific terminology rather than external system language.
 */
public enum MealPreference {
    NONE("No special dietary requirements"),
    VEGETARIAN("Vegetarian meals"),
    GLUTEN_FREE("Gluten-free meals"),
    VEGAN("Vegan meals"),
    HALAL("Halal meals"),
    KOSHER("Kosher meals");

    private final String description;

    MealPreference(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }

    /**
     * Returns whether this preference requires special meal preparation.
     */
    public boolean requiresSpecialPreparation() {
        return this != NONE;
    }

    /**
     * Returns whether this preference is plant-based.
     */
    public boolean isPlantBased() {
        return this == VEGETARIAN || this == VEGAN;
    }

    @Override
    public String toString() {
        return description;
    }
}
```

### TShirtSize.java

Create the `TShirtSize` value object in the `valueobjects` package:

```java
package dddhexagonalworkshop.conference.attendees.domain.valueobjects;

/**
 * Represents t-shirt sizes available for conference attendees.
 * Defines the sizes our domain supports, independent of external systems.
 */
public enum TShirtSize {
    S("Small"),
    M("Medium"), 
    L("Large"),
    XL("Extra Large"),
    XXL("Extra Extra Large");

    private final String displayName;

    TShirtSize(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    /**
     * Returns the relative size order for comparison purposes.
     */
    public int getSizeOrder() {
        return switch (this) {
            case S -> 1;
            case M -> 2;
            case L -> 3;
            case XL -> 4;
            case XXL -> 5;
        };
    }

    /**
     * Checks if this size is larger than the given size.
     */
    public boolean isLargerThan(TShirtSize other) {
        return this.getSizeOrder() > other.getSizeOrder();
    }

    /**
     * Returns the next larger size, if available.
     */
    public TShirtSize getNextLargerSize() {
        return switch (this) {
            case S -> M;
            case M -> L;
            case L -> XL;
            case XL -> XXL;
            case XXL -> XXL; // No larger size available
        };
    }

    @Override
    public String toString() {
        return displayName;
    }
}
```

## Key Design Decisions

### 1. Domain-Specific Terminology

**MealPreference vs DietaryRequirements:**
- Our domain uses "preference" (choice-oriented)
- External system uses "requirements" (constraint-oriented)
- Domain language is more customer-friendly

**TShirtSize vs Size:**
- Our domain is specific about t-shirts
- External system uses generic "size"
- Domain is more precise and contextual

### 2. Rich Behavior

Both value objects include behavior beyond simple data:

**MealPreference methods:**
- `requiresSpecialPreparation()` - business logic
- `isPlantBased()` - categorization logic
- `getDescription()` - human-readable information

**TShirtSize methods:**
- `getSizeOrder()` - comparison support
- `isLargerThan()` - business comparison
- `getNextLargerSize()` - inventory management support

### 3. Domain Rules Encoded

**MealPreference:**
- Supports more options than external system (VEGAN, HALAL, KOSHER)
- Enables future expansion without breaking external integration
- Provides business categorization methods

**TShirtSize:**
- Deliberately excludes XS (business decision)
- Provides size comparison logic
- Includes inventory-oriented methods

### 4. Independent Evolution

- Domain enums can evolve independently of external systems
- Anti-Corruption Layer handles the mapping
- Business logic stays in domain layer

## Integration with Anti-Corruption Layer

The ACL translator maps external concepts to these domain concepts:

```java
// External -> Domain mapping
DietaryRequirements.VEGETARIAN -> MealPreference.VEGETARIAN
DietaryRequirements.GLUTEN_FREE -> MealPreference.GLUTEN_FREE
DietaryRequirements.NONE -> MealPreference.NONE

// Size mapping with business logic
Size.XS -> TShirtSize.S  // Business rule: no XS in our domain
Size.S -> TShirtSize.S
Size.M -> TShirtSize.M
// ... etc
```

## Benefits of This Approach

1. **Domain Clarity**: Clear, business-focused terminology
2. **Rich Modeling**: Value objects contain relevant business behavior
3. **Independent Evolution**: Domain can evolve without breaking integration
4. **Type Safety**: Compile-time guarantees about valid values
5. **Business Logic Encapsulation**: Rules live close to the data

## Future Considerations

These value objects can be enhanced with:
- **Validation logic** for input data
- **Formatting methods** for different display contexts
- **Business rules** specific to conference management
- **Internationalization** support for descriptions

## Next Step

Continue to [Step 5: Update the RegisterAttendeeCommand](step5-update-command.md)
