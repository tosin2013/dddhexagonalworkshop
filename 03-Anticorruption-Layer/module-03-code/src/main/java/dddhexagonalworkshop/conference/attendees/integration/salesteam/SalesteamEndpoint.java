package dddhexagonalworkshop.conference.attendees.integration.salesteam;

import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;
import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeService;
import io.quarkus.logging.Log;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.util.List;

@Path("/salesteam")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class SalesteamEndpoint {

    @Inject
    AttendeeService attendeeService;

    @POST
    public Response registerAttendees(SalesteamRegistrationRequest salesteamRegistrationRequest) {
        return Response.accepted().build();
    }
}