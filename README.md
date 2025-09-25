# A Hands On Introduction to Domain-Driven Design and Hexagonal Architecture Workshop

Welcome to the **Domain-Driven Design (DDD) with Hexagonal Architecture Workshop**! This hands-on workshop will guide you through implementing core DDD concepts while building a demo registration system for conference attendees.

This workshop is for anyone who likes to get their hands on a keyboard as part of the learning process. Your project authors believe that architecture is best learned through practice, and this workshop provides a structured way to apply Domain-Driven Design (DDD) principles in a practical context.

There is a great deal of theory in Domain Driven Design. This workshop was built because while the authors love talking about software architecture (their colleagues will verify), they also like getting their hands dirty with code. In fact, your workshop authors believe that it is impossible to understand software architecture **_without_** getting your hands on a keyboard and implementing the ideas.

## 🚀 Quick Start

### For Workshop Instructors (Multi-User)
```bash
# Setup cluster prerequisites (one-time)
./scripts/deploy-workshop.sh --cluster-setup

# Deploy workshop for 20 users
./scripts/deploy-workshop.sh --workshop --count 20

# Generate access URLs
./scripts/deploy-workshop.sh --workshop --generate-urls --use-existing
```

### For Individual Developers (Single-User)
```bash
# Deploy personal workshop environment
./scripts/deploy-workshop.sh --single-user --namespace my-workshop

# Test your deployment
./scripts/deploy-workshop.sh --test --single-user
```

### OpenShift Dev Spaces (Direct Access)
**Complete Environment with Java 21 + PostgreSQL + Kafka:**
```
https://devspaces.apps.<your-cluster-domain>#https://github.com/tosin2013/dddhexagonalworkshop.git&devfilePath=devfile.yaml
```

**📖 Deployment Guides:**
- **[Consolidated Scripts Guide](docs/CONSOLIDATED_SCRIPTS_GUIDE.md)** - New unified deployment system
- **[Complete Environment Setup Guide](docs/devfile-complete-setup-guide.md)** - Dev Spaces setup
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Comprehensive deployment instructions
## 🎯 Workshop Overview

This workshop is for anyone who likes to get their hands on a keyboard as part of the learning process. Your project authors believe that architecture is best learned through practice, and this workshop provides a structured way to apply Domain-Driven Design (DDD) principles in a practical context.

In this introductory workshop, you'll learn to apply Domain-Driven Design principles by building a microservice for managing conference attendee registrations. You'll implement the complete workflow from receiving HTTP requests to persisting data and publishing events, all while maintaining clean architectural boundaries.

### What We'll Build

By the end of this workshop, you will have implemented an attendee registration system that demonstrates:

- **Domain-Driven Design**: Business-focused modeling and implementation
- **Event-Driven Communication**: Asynchronous integration through domain events
- **Hexagonal Architecture**: Creation of loosely coupled application components that can be easily composed; also known as ports and adapters
- **Inbound Adapters**: HTTP endpoint implementation
- **Outbound Adapters**: Persistent storage with proper domain/persistence separation and messaging with Kafka

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


### Our Learning Strategy

Each workshop module contains a pre-built directory with stubbed out classes, like the one below.

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeService;
import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;
import io.quarkus.logging.Log;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.net.URI;


/**
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter,   * which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on   * all sides of it, without actually knowing the nature of the things on the other side of the adapters."
 * Alistair Cockburn, Hexagonal Architecture, 2005.
 *
 */
public class AttendeeEndpoint {
}

```

The documentation contains the code to complete the classes:

```java
package dddhexagonalworkshop.conference.attendees.infrastructure;

import dddhexagonalworkshop.conference.attendees.domain.services.AttendeeService;
import dddhexagonalworkshop.conference.attendees.domain.services.RegisterAttendeeCommand;
import io.quarkus.logging.Log;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.net.URI;


/**
 * "The application is blissfully ignorant of the nature of the input device. When the application has something to send out, it sends it out through a port to an adapter,   * which creates the appropriate signals needed by the receiving technology (human or automated). The application has a semantically sound interaction with the adapters on   * all sides of it, without actually knowing the nature of the things on the other side of the adapters."
 * Alistair Cockburn, Hexagonal Architecture, 2005.
 *
 */
@Path("/attendees")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class AttendeeEndpoint {

    @Inject
    AttendeeService attendeeService;

    @POST
    public Response registerAttendee(RegisterAttendeeCommand registerAttendeeCommand) {
        Log.debugf("Creating attendee %s", registerAttendeeCommand);

        AttendeeDTO attendeeDTO = attendeeService.registerAttendee(registerAttendeeCommand);

        Log.debugf("Created attendee %s", attendeeDTO);

        return Response.created(URI.create("/" + attendeeDTO.email())).entity(attendeeDTO).build();
    }

}
```

You can implement the classes by typing in the supplied code, which is your workshop authors preferred method because we believe it is easier to remember that way, or by copying and pasting.  Each step will cover a particular DDD topic.

The examples are not meant to be reflect a production system so you will find, for instance, that validation might not be as complete as it would in a real application.

### :rocket: tl;dr

Each step starts with a **tl;dr** section containing only code.  If you want to get the application up and running as quickly as possible you can copy/paste the code into the stubbed classes without reading the rest of the material.

We think this can be a good approach if you are as impatient as (one of) us, but we hope you go back through the material and read through each step.

---

## Workshop Overview

### What We Are Building

A conference attendee registration microservice with:

- **REST API** for registering attendees
- **Business logic** that validates registrations
- **Event publishing** to notify other systems
- **Database persistence** for attendee data
- **Clean architecture** that separates concerns

### The Journey (3 Modules)

We'll build this system step-by-step, with each piece compiling as we go:

| Module | Component                 | Focus                                                                 |
| --------- | ------------------------- | --------------------------------------------------------------------- |
| [01](/01-End-to-End-DDD/Overview.md)        | **End to End DDD**        | Implement a (very) basic workflow                                     |
| [02](/02-Value-Objects/Overview.md)        | **Value Objects**         | Add more detail to the basic workflow                                 |
| [03](/03-Anti-Corruption-Layer.md)        | **Anti-Corruption Layer** | Implement an Anti Corruption Layer to integrate with external systems |
| [04](/04-Testing/Overview.md)        | **Testability**           | Focus on testing                                                      |

---

### Module 1 (10 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component           | Focus                       |
| ---- | ------------------- | --------------------------- |
| [01](/01-End-to-End-DDD/01-Events.md)   | **Events**          | Capture business facts      |
| [02](/01-End-to-End-DDD/02-Commands.md)   | **Commands**        | Represent business requests |
| [03](/01-End-to-End-DDD/03-Combining-Return-Values.md)   | **Result Objects**  | Combine multiple outputs    |
| [04](/01-End-to-End-DDD/04-Aggregates.md)   | **Aggregates**      | Core business logic         |
| [05](/01-End-to-End-DDD/05-Entities.md)   | **Entities**        | Database mapping            |
| [06](/01-End-to-End-DDD/06-Repositories.md)   | **Repositories**    | Data access layer           |
| [07](/01-End-to-End-DDD/07-Outbound-Adapters.md)   | **Event Publisher** | Messaging integration       |
| [08](/01-End-to-End-DDD/08-Application-Services.md)   | **Domain Services** | Workflow orchestration      |
| [09](/01-End-to-End-DDD/09-Data-Transfer-Objects.md)   | **DTOs**            | API data contracts          |
| [10](/01-End-to-End-DDD/10-Inbound-Adapters.md)   | **REST Endpoint**   | HTTP interface              |

---

### Module 2 (7 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Focus                       |
| ---- | -------------------------------------- | --------------------------- |
| [01](/02-Value-Objects/01-Value-Objects.md)   | **Create the Address Value Object**    | Capture business facts      |
| [02](/02-Value-Objects/02-Update-the-Command.md)   | **Update the RegisterAttendeeCommand** | Represent business requests |
| [03](/02-Value-Objects/03-Update-the-Aggregate.md)   | **Update the Attendee Aggregate**      | Package multiple outputs    |
| [04](/02-Value-Objects/04-Update-the-Event.md)   | **Update the AttendeeRegisteredEvent** | Core business logic         |
| [05](/02-Value-Objects/05-Update-Persistence.md)   | **Update the Persistence Layer**       | Database mapping            |
| [06](/02-Value-Objects/06-Update-the-DTO.md)   | **Update the AttendeeService**         | Data access layer           |
| [07](/02-Value-Objects/07-Update-the-Service.md)   | **Update the AttendeeDTO**             | Messaging integration       |

---

### Module 3 (5 Steps)

We'll build this system step-by-step, with each piece compiling as we go:

| Step | Component                              | Focus                       |
| ---- | -------------------------------------- | --------------------------- |
| [01](03-Anti-Corruption-Layer/01-The-External-System.md)   | **Create the Address Value Object**    | Capture business facts      |
| [02](03-Anti-Corruption-Layer/02-Implement-a-Translator.md)   | **Update the RegisterAttendeeCommand** | Represent business requests |
| [03](03-Anti-Corruption-Layer/03-Inbound-Adapter.md)   | **Update the Attendee Aggregate**      | Package multiple outputs    |
| [04](03-Anti-Corruption-Layer/04-Value-Objects.md)   | **Update the AttendeeRegisteredEvent** | Core business logic         |
| [05](03-Anti-Corruption-Layer/05-Update-the-Command.md)   | **Update the Persistence Layer**       | Database mapping            |


## Key Concepts We'll Experience

### Domain-Driven Design (DDD)

- **Business logic in the right place** - not scattered across layers
- **Rich domain models** that express business concepts clearly
- **Clean separation** between business rules and technical concerns

### Hexagonal Architecture

- **Ports and Adapters** pattern that keeps your core domain pure
- **Technology independence** - swap databases or frameworks easily
- **Testable design** with clear boundaries

### The Big Picture

```
External World → REST → Domain Logic → Events → External Systems
     ↓              ↓         ↓           ↓           ↓
  HTTP Requests → Commands → Aggregates → Events → Kafka
                     ↓         ↓           ↓
                  DTOs ← Domain Service → Repository → Database
```

---

## Workshop Rules for Success

### ✅ **Do This:**

- **Follow along step-by-step** - don't jump ahead
- **Copy code exactly** - before experimenting.  Once everything is working, experiment all you want
- **Ask for help** if you get stuck

### ❌ **Avoid This:**

- **Don't optimize or change the code** - get it working first
- **Don't get stuck on theory questions** - ask theory questions!
- **Don't get stuck on implementation questions** - ask implementation questions!

### 🆘 **If You Fall Behind:**

- **Don't panic** - the goal is learning, not perfection
- **Revisit at a later date** - the workshop will be on GitHub, the authors are easy to get in touch with, and happy to help at any time

---

<<<<<<< HEAD
## Workshop Environment Options

There are 3 ways to do the workshop:

### 🏢 **OpenShift Dev Spaces** (Recommended for Enterprise)

**Multi-User Workshop Cluster Setup:**
- **Cluster**: OpenShift 4.14+ cluster with admin access
- **URL**: https://api.<your-cluster-domain>:6443
- **Users**: Supports multiple users (user01, user02, etc.)
- **Architecture**: Per-user infrastructure with shared Dev Spaces operator

**Setup Requirements:**
1. **Cluster Admin Setup** (One-time):
   ```bash
   # Install OpenShift Dev Spaces operator cluster-wide
   ./scripts/setup-cluster-devspaces.sh
   ```

2. **Per-User Infrastructure** (For each participant):
   ```bash
   # Deploy infrastructure for specific user
   ./scripts/deploy-user-infrastructure.sh user01

   # Or deploy for multiple users at once
   ./scripts/deploy-user-infrastructure.sh --multiple 10
   ```

3. **User Access**:
   - Access Dev Spaces URL (provided after cluster setup)
   - Create workspace with: `https://github.com/jeremyrdavis/dddhexagonalworkshop.git`
   - Use user-specific devfile: `devfile-user01.yaml`

**Current Cluster Status:**
- ✅ **Cluster**: Active (3 control-plane + 2 worker nodes)
- ❌ **Dev Spaces Operator**: Needs installation/repair
- ⚠️ **Infrastructure**: Partial deployment (PostgreSQL ✅, Kafka ❌)

📖 **Detailed Guide**: [OpenShift Dev Spaces Setup](docs/OPENSHIFT_DEV_SPACES.md)

### 💻 **GitHub Codespaces** (Individual Development)

- GitHub Codespace: [GitHub Codespaces](GitHub-Codespaces.md)

### 🖥️ **Local Development** (Traditional Setup)

- Quarkus' Dev Mode on your laptop: [Quarkus Local](Quarkus-Local.md)

### Why OpenShift Dev Spaces? (New!)

- **🏢 Enterprise Ready**: Built for enterprise OpenShift environments with security and compliance
- **🔧 Zero Setup**: Pre-configured development environment with all dependencies
- **🐳 Container Native**: Demonstrates cloud-native development patterns with sidecar architecture
- **🔒 Secure**: Runs in isolated containers with proper security contexts
- **📊 Observable**: Built-in monitoring and health checks for educational purposes
- **⚡ Fast Startup**: Optimized container images and startup sequences
- **🎯 Workshop Focused**: Specifically designed for DDD and Hexagonal Architecture learning

OpenShift Dev Spaces provides the most realistic cloud-native development experience, showing how modern applications are built and deployed in enterprise environments.

## 🔧 Workshop Cluster Management

### Current Cluster Status Check

```bash
# Check cluster connectivity
oc whoami
oc cluster-info

# Check Dev Spaces operator status
oc get csv -n openshift-devspaces

# Check existing workshop infrastructure
oc get namespaces | grep -E "(devspaces|ddd-workshop)"
oc get all -n ddd-workshop
```

### Cluster Reset/Cleanup (If Needed)

```bash
# Clean up failed deployments
helm uninstall ddd-workshop -n ddd-workshop

# Clean up failed operators (cluster-admin required)
oc delete csv devspacesoperator.v3.22.0 -n openshift-devspaces
oc delete csv devworkspace-operator.v0.35.1 -n openshift-devspaces

# Clean up namespaces
oc delete namespace ddd-workshop
oc delete namespace openshift-devspaces
```

### Fresh Installation Process

1. **Verify Cluster Access**:
   ```bash
   oc whoami  # Should show: admin
   oc auth can-i create clusterroles  # Should show: yes
   ```

2. **Install Dev Spaces Operator**:
   ```bash
   ./scripts/setup-cluster-devspaces.sh
   ```

3. **Deploy User Infrastructure**:
   ```bash
   # Single user
   ./scripts/deploy-user-infrastructure.sh user01

   # Multiple users (workshop batch)
   ./scripts/deploy-user-infrastructure.sh --multiple 10
   ```

4. **Verify Deployment**:
   ```bash
   # Check operator status
   oc get checluster devspaces -n openshift-devspaces

   # Check user infrastructure
   oc get all -n ddd-workshop-user01
   ```

### Multi-User Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenShift Cluster                        │
├─────────────────────────────────────────────────────────────┤
│  openshift-devspaces (Cluster-wide)                        │
│  ├── Dev Spaces Operator                                   │
│  ├── DevWorkspace Operator                                 │
│  └── CheCluster (Multi-user configuration)                 │
├─────────────────────────────────────────────────────────────┤
│  ddd-workshop-user01                                        │
│  ├── PostgreSQL (user01 database)                          │
│  ├── Kafka (user01 topics)                                 │
│  └── Services & Routes                                      │
├─────────────────────────────────────────────────────────────┤
│  ddd-workshop-user02                                        │
│  ├── PostgreSQL (user02 database)                          │
│  ├── Kafka (user02 topics)                                 │
│  └── Services & Routes                                      │
├─────────────────────────────────────────────────────────────┤
│  user01-devspaces (Auto-created by Dev Spaces)             │
│  └── Quarkus Development Workspace                         │
└─────────────────────────────────────────────────────────────┘
```

### 🚨 Common Issues and Solutions

#### Issue 1: Dev Spaces Operator in Failed State
```bash
# Check operator logs
oc logs -n openshift-devspaces deployment/devspaces-operator

# Solution: Clean up and reinstall
oc delete csv -n openshift-devspaces --all
./scripts/setup-cluster-devspaces.sh
```

#### Issue 2: Kafka Container CrashLoopBackOff
```bash
# Check Kafka pod logs
oc logs -n ddd-workshop-user01 deployment/ddd-workshop-user01-kafka

# Common cause: AMQ Streams image requires Strimzi operator
# Solution: Using Bitnami Kafka image (already configured)
```

#### Issue 3: User Cannot Access Their Infrastructure
```bash
# Check user permissions
oc get rolebindings -n ddd-workshop-user01

# Grant access if missing
oc adm policy add-role-to-user admin user01 -n ddd-workshop-user01
```

#### Issue 4: Workspace Cannot Connect to Services
```bash
# Check service endpoints
oc get endpoints -n ddd-workshop-user01

# Verify devfile service URLs match namespace
# Should be: ddd-workshop-user01-postgresql.ddd-workshop-user01.svc.cluster.local
```

### 📊 Resource Requirements

**Per User:**
- **Memory**: 2.5GB (PostgreSQL: 512MB, Kafka: 1GB, Quarkus: 1GB)
- **CPU**: 1 core (PostgreSQL: 0.2, Kafka: 0.3, Quarkus: 0.5)
- **Storage**: 5GB ephemeral

**Workshop Scaling:**
- **10 users**: ~25GB memory, ~10 CPU cores
- **25 users**: ~62GB memory, ~25 CPU cores
- **50 users**: ~125GB memory, ~50 CPU cores

**Current Cluster Capacity:**
- **Nodes**: 3 control-plane + 2 worker nodes
- **Estimated Capacity**: ~20-30 concurrent users

## 🎯 Quick Start for Workshop Instructors

### Pre-Workshop Setup (30 minutes before workshop)

1. **Verify Cluster Access**:
   ```bash
   oc login --token=<your-token> --server=https://api.<your-cluster-domain>:6443
   oc whoami  # Should show: admin
   ```

2. **Clean Up Previous Sessions** (if needed):
   ```bash
   # Remove old deployments
   helm list -A | grep ddd-workshop | awk '{print $1 " -n " $2}' | xargs -r helm uninstall

   # Clean up namespaces
   oc get namespaces | grep ddd-workshop | awk '{print $1}' | xargs -r oc delete namespace
   ```

3. **Install Dev Spaces Operator**:
   ```bash
   ./scripts/setup-cluster-devspaces.sh
   # Wait for completion (~5-10 minutes)
   ```

4. **Deploy Infrastructure for Expected Users**:
   ```bash
   # For 10 users (user01-user10)
   ./scripts/deploy-user-infrastructure.sh --multiple 10
   # Wait for completion (~10-15 minutes)
   ```

## 🎯 Quick Start for Workshop Instructors

### Pre-Workshop Setup (30 minutes before workshop)

1. **Verify Cluster Access**:
   ```bash
   oc login --token=<your-token> --server=https://api.<your-cluster-domain>:6443
   oc whoami  # Should show: admin
   ```

2. **Clean Up Previous Sessions** (if needed):
   ```bash
   # Remove old deployments
   helm list -A | grep ddd-workshop | awk '{print $1 " -n " $2}' | xargs -r helm uninstall

   # Clean up namespaces
   oc get namespaces | grep ddd-workshop | awk '{print $1}' | xargs -r oc delete namespace
   ```

3. **Install Dev Spaces Operator**:
   ```bash
   ./scripts/setup-cluster-devspaces.sh
   # Wait for completion (~5-10 minutes)
   ```

4. **Deploy Infrastructure for Expected Users**:
   ```bash
   # For 10 users (user01-user10)
   ./scripts/deploy-user-infrastructure.sh --multiple 10
   # Wait for completion (~10-15 minutes)
   ```

5. **Verify Everything is Ready**:
   ```bash
   # Check Dev Spaces URL
   oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}'

   # Check sample user infrastructure
   oc get all -n ddd-workshop-user01
   ```

### During Workshop

**Share with Participants:**
- **Dev Spaces URL**: `oc get checluster devspaces -n openshift-devspaces -o jsonpath='{.status.cheURL}'`
- **Repository**: `https://github.com/jeremyrdavis/dddhexagonalworkshop.git`
- **User-specific devfile**: `devfile-user01.yaml` (replace with their user number)

**Monitor Resources:**
```bash
# Check cluster resource usage
oc top nodes

# Check user workspaces
oc get devworkspace -A

# Check infrastructure health
./scripts/validate-resources.sh
```

### Post-Workshop Cleanup

```bash
# Clean up all user infrastructure
for i in {01..10}; do
  ./scripts/deploy-user-infrastructure.sh --cleanup user$i
done

# Optional: Remove Dev Spaces operator
oc delete checluster devspaces -n openshift-devspaces
oc delete namespace openshift-devspaces
```

=======
## Hands-on-Keyboards Checklist 

There are 2 ways to do the workshop:

- GitHub Codespace: [GitHub Codespaces](GitHub-Codespaces.md)

- Quarkus' Dev Mode on your laptop: [Quarkus Local](Quarkus-Local.md)

>>>>>>> f861209fcd2da931cc03efb6207550f58a118e05
### Why Quarkus?

- **⚡ Supersonic, Subatomic Java**: Incredibly fast startup times and low memory usage
- **🔧 Developer Experience**: Live reload during development - see changes instantly
- **🐳 Container First**: Built for Kubernetes and cloud deployment from the ground up
- **📦 Unified Configuration**: Single configuration model for all extensions
- **🎯 Standards-Based**: Built on proven standards like JAX-RS, CDI, and JPA

Most importantly, Quarkus gets out of your way, allowing you to focus on your code.

Your workshop authors work for Red Hat, the company behind Quarkus, but we believe that Quarkus is the best choice because it allows you to focus on implementing Domain-Driven Design (DDD) concepts without worrying about boilerplate code or complex configurations.

[Quarkus Website](https://quarkus.io/)

### Workshop-Specific Benefits

**Dev Mode Magic**: Quarkus automatically starts and manages external dependencies:

```bash
./mvnw quarkus:dev
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

## 📚 Documentation

### Deployment Guides

- **[Workshop Deployment Guide](docs/DEPLOYMENT_GUIDE.md)**: Multi-user workshop setup and management
  - HTPasswd user creation and management
  - OpenShift Dev Spaces configuration
  - Resource monitoring and troubleshooting
  - **Use for**: Workshop facilitators, educational environments

- **[Production Deployment Guide](docs/PRODUCTION_DEPLOYMENT.md)**: Application deployment for dev/staging/prod
  - Helm chart customization
  - Environment-specific configurations
  - Production monitoring and scaling
  - **Use for**: DevOps teams, application deployment

### Additional Resources

- **[OpenShift Dev Spaces Guide](docs/OPENSHIFT_DEV_SPACES.md)**: Complete Dev Spaces usage guide
- **[Complete Environment Setup](docs/devfile-complete-setup-guide.md)**: Devfile configuration details

## Get Started!

[01 End to End DDD](01-End-to-End-DDD/README.md)
