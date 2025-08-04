# OpenShift Dev Spaces Guide
## DDD Hexagonal Architecture Workshop

Welcome to the **OpenShift Dev Spaces** version of the DDD Hexagonal Architecture Workshop! This guide will help you get started with the workshop using Red Hat's cloud-native development environment.

## 🚀 Quick Start

### Option 1: Red Hat Workshop Cluster (Recommended)

If you're participating in a Red Hat workshop, use the pre-configured cluster:

1. **Access the Workshop Environment**
   - Open your browser and navigate to the provided OpenShift Dev Spaces URL
   - Login with your workshop credentials

2. **Create a New Workspace**
   - Click "Create Workspace"
   - Enter the repository URL: `https://github.com/jeremyrdavis/dddhexagonalworkshop.git`
   - The devfile.yaml will automatically configure your environment

3. **Wait for Environment Setup**
   - PostgreSQL container starts first
   - Kafka container starts second
   - Quarkus development container starts last
   - Maven dependencies are automatically resolved

4. **Start Coding!**
   - Navigate to `01-End-to-End-DDD/module-01-code`
   - Open a terminal and run: `./mvnw quarkus:dev`
   - Access your application at the provided URL

### Option 2: Your Own OpenShift Cluster

If you have access to your own OpenShift cluster:

1. **Deploy the Workshop Infrastructure**
   ```bash
   git clone https://github.com/jeremyrdavis/dddhexagonalworkshop.git
   cd dddhexagonalworkshop
   ./scripts/deploy-to-openshift.sh --namespace ddd-workshop --environment dev
   ```

2. **Access OpenShift Dev Spaces**
   - Navigate to your OpenShift Dev Spaces instance
   - Create a workspace using this repository

## 🏗️ Architecture Overview

The OpenShift Dev Spaces environment uses a **sidecar pattern** with three containers:

```
┌─────────────────────────────────────────────────────────────┐
│                    OpenShift Dev Spaces                     │
├─────────────────┬─────────────────┬─────────────────────────┤
│   PostgreSQL    │     Kafka       │    Quarkus Dev          │
│   Container     │   Container     │    Container            │
│                 │                 │                         │
│ • Database      │ • Message       │ • Development           │
│ • Port 5432     │   Broker        │   Environment           │
│ • Ephemeral     │ • Port 9092     │ • Port 8080 (external)  │
│   Storage       │ • Auto-create   │ • Port 5005 (debug)     │
│                 │   Topics        │ • Maven Cache           │
└─────────────────┴─────────────────┴─────────────────────────┘
```

### Container Specifications

#### PostgreSQL Container
- **Image**: `registry.redhat.io/rhel8/postgresql-15:latest`
- **Resources**: 512Mi memory, 200m CPU
- **Database**: `conference`
- **User**: `attendee` / Password: `workshop`
- **Storage**: Ephemeral (resets on workspace restart)

#### Kafka Container
- **Image**: `registry.redhat.io/amq7/amq-streams-kafka-35-rhel8:latest`
- **Resources**: 1Gi memory, 300m CPU
- **Bootstrap Servers**: `localhost:9092`
- **Auto-create Topics**: Enabled
- **Storage**: Ephemeral (resets on workspace restart)

#### Quarkus Development Container
- **Image**: `registry.access.redhat.com/ubi8/openjdk-21:1.20`
- **Resources**: 1Gi memory, 500m CPU
- **Ports**: 8080 (HTTP), 5005 (Debug)
- **Maven Cache**: Persistent during workspace session

## 🔧 Development Workflow

### Starting Your First Module

1. **Navigate to Module 01**
   ```bash
   cd 01-End-to-End-DDD/module-01-code
   ```

2. **Start Quarkus Development Mode**
   ```bash
   ./mvnw quarkus:dev
   ```

3. **Access Your Application**
   - Click on the "Open in Browser" notification
   - Or use the exposed port URL shown in the terminal

4. **Explore the Development Features**
   - **Live Reload**: Changes are automatically reflected
   - **Dev UI**: Access at `/q/dev`
   - **Health Checks**: Access at `/q/health`
   - **Swagger UI**: Access at `/q/swagger-ui`

### Working with Different Modules

The workshop has three modules, each building on the previous:

#### Module 01: End-to-End DDD
```bash
cd 01-End-to-End-DDD/module-01-code
./mvnw quarkus:dev
```
**Focus**: Basic DDD concepts, Events, Commands, Aggregates

#### Module 02: Value Objects
```bash
cd 02-Value-Objects/module-02-code
./mvnw quarkus:dev
```
**Focus**: Implementing Value Objects, enhancing the domain model

#### Module 03: Anti-Corruption Layer
```bash
cd 03-Anticorruption-Layer/module-03-code
./mvnw quarkus:dev
```
**Focus**: Integration patterns, external system interaction

### Database and Messaging

#### PostgreSQL Database
- **Connection**: Automatically configured
- **Schema**: Auto-generated on startup
- **Data**: Ephemeral (perfect for workshop experimentation)

#### Kafka Messaging
- **Topics**: Auto-created as needed
- **Messages**: Can be inspected using Kafka tools
- **Integration**: Seamlessly connected to Quarkus

## 🛠️ Available Commands

The devfile provides several pre-configured commands:

### Development Commands
- **dev-run**: Start Quarkus in development mode
- **dev-debug**: Start with debug port enabled
- **compile**: Compile the project
- **test**: Run unit tests
- **package**: Package the application

### Infrastructure Commands
- **check-postgresql**: Verify PostgreSQL connectivity
- **check-kafka**: Verify Kafka connectivity

### Module Navigation
- **module-01**: Switch to Module 01 directory
- **module-02**: Switch to Module 02 directory
- **module-03**: Switch to Module 03 directory

## 🔍 Troubleshooting

### Common Issues

#### 1. Containers Not Starting
**Symptoms**: Workspace fails to start or containers are in error state

**Solutions**:
- Check resource limits in your OpenShift cluster
- Verify the devfile.yaml is properly configured
- Check container logs in the OpenShift console

#### 2. Database Connection Issues
**Symptoms**: Quarkus fails to connect to PostgreSQL

**Solutions**:
```bash
# Check PostgreSQL status
nc -z localhost 5432

# Test database connection
PGPASSWORD=workshop psql -h localhost -p 5432 -U attendee -d conference -c "SELECT 1;"

# Check environment variables
echo $QUARKUS_DATASOURCE_JDBC_URL
```

#### 3. Kafka Connection Issues
**Symptoms**: Messaging features not working

**Solutions**:
```bash
# Check Kafka status
nc -z localhost 9092

# List topics (if kafka tools are available)
kafka-topics.sh --bootstrap-server localhost:9092 --list

# Check environment variables
echo $KAFKA_BOOTSTRAP_SERVERS
```

#### 4. Port Access Issues
**Symptoms**: Cannot access application in browser

**Solutions**:
- Check if the port is properly exposed in the devfile
- Verify the application is running on 0.0.0.0, not localhost
- Check OpenShift route configuration

### Debug Commands

```bash
# Check all environment variables
env | grep -E "(QUARKUS|KAFKA|POSTGRES)"

# Test network connectivity
./scripts/network-troubleshoot.sh

# Check container processes
ps aux | grep -E "(postgres|kafka|java)"

# View application logs
tail -f target/quarkus.log
```

## 🎯 Workshop Tips

### Best Practices

1. **Save Your Work Frequently**
   - Workspaces are ephemeral
   - Commit changes to Git regularly
   - Use the integrated Git features

2. **Use Live Reload Effectively**
   - Make small changes and observe results
   - Use the Dev UI for quick testing
   - Leverage hot reload for rapid development

3. **Explore the Architecture**
   - Examine the container setup
   - Understand the networking between services
   - Learn from the devfile configuration

4. **Take Advantage of Observability**
   - Use health checks to understand system state
   - Explore metrics and monitoring features
   - Learn about cloud-native operational patterns

### Learning Objectives

By using OpenShift Dev Spaces, you'll learn:

- **Container-based Development**: How modern applications are developed
- **Service Architecture**: How microservices communicate
- **Cloud-Native Patterns**: Sidecar pattern, health checks, observability
- **Enterprise Development**: Security, resource management, scalability
- **DevOps Integration**: How development environments integrate with deployment

## 📚 Additional Resources

- **OpenShift Dev Spaces Documentation**: https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces
- **Devfile Specification**: https://devfile.io/
- **Quarkus Guides**: https://quarkus.io/guides/
- **Workshop Repository**: https://github.com/jeremyrdavis/dddhexagonalworkshop

## 🆘 Getting Help

If you encounter issues:

1. **Check the troubleshooting section above**
2. **Review the deployment guide**: [docs/DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
3. **Contact the workshop instructor**
4. **Open an issue in the GitHub repository**

---

**Author**: Tosin Akinsoho <takinosh@redhat.com>  
**Repository**: https://github.com/jeremyrdavis/dddhexagonalworkshop  
**Workshop Focus**: Domain-Driven Design and Hexagonal Architecture
