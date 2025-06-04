package dddhexagonalworkshop.conference.attendees.integration.salesteam;

import dddhexagonalworkshop.conference.attendees.domain.valueobjects.TShirtSize;
import dddhexagonalworkshop.conference.attendees.domain.valueobjects.MealPreference;
import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;

import java.util.List;

public class SalesteamToDomainTranslator {

    public static List<RegisterAttendeeCommand> translate(List<Customer> customers) {
        return customers.stream()
                .map(customer -> new RegisterAttendeeCommand(
                        customer.email(),
                        customer.firstName(),
                        customer.lastName(),
                        null,
                        mapDietaryRequirements(customer.customerDetails().dietaryRequirements()),
                        mapTShirtSize(customer.customerDetails().size()))).toList();
    }

    private static MealPreference mapDietaryRequirements(DietaryRequirements dietaryRequirements) {
        if (dietaryRequirements == null) {
            return MealPreference.NONE;
        }
        return switch (dietaryRequirements) {
            case VEG -> MealPreference.VEGETARIAN;
            case GLF -> MealPreference.GLUTEN_FREE;
            case NA -> MealPreference.NONE;
        };
    }

    private static TShirtSize mapTShirtSize(Size size) {
        if (size == null) {
            return null;
        }
        return switch (size) {
            case Size.XS -> TShirtSize.S;
            case Size.S -> TShirtSize.S;
            case Size.M -> TShirtSize.M;
            case Size.L -> TShirtSize.L;
            case Size.XL -> TShirtSize.XL;
            case Size.XXL -> TShirtSize.XXL;
            default -> null;
        };
    }
}
