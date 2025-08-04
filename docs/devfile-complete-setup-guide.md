# Complete Workshop Environment Setup Guide

## Overview

This guide walks you through setting up and validating the complete DDD Hexagonal Architecture Workshop environment using `devfile-complete.yaml`. This environment includes Java 21, PostgreSQL, and Kafka containers, supporting all 22 workshop exercises without limitations.

## Prerequisites

- Access to OpenShift Dev Spaces cluster
- Valid user credentials (e.g., user1)
- Workshop repository: https://github.com/tosin2013/dddhexagonalworkshop.git

## Environment Specifications

### Container Architecture
```
Complete Workshop Environment (devfile-complete.yaml)
├── Java 21 Development Container (768Mi memory, 500m CPU)
│   ├── OpenJDK 21 runtime
│   ├── Maven build tools
│   └── Quarkus development environment
├── PostgreSQL Sidecar (384Mi memory, 200m CPU)
│   ├── Database: conference
│   ├── User: attendee / Password: workshop
│   └── Port: localhost:5432
└── Kafka Sidecar (768Mi memory, 300m CPU)
    ├── Single-node Kafka cluster
    ├── Auto-create topics enabled
    └── Port: localhost:9092

Total Resources: ~1.9Gi memory, 1000m CPU per workspace
```

## Step 1: Create Complete Workshop Environment

### Option A: Direct URL (Recommended)
```
https://devspaces.apps.<your-cluster-domain>#https://github.com/tosin2013/dddhexagonalworkshop.git&devfilePath=devfile-complete.yaml
```

### Option B: Manual Creation
1. **Access Dev Spaces**: https://devspaces.apps.<your-cluster-domain>
2. **Login**: Enter your credentials (e.g., user1 / password)
3. **Create Workspace**: Click "Create Workspace"
4. **Repository URL**: `https://github.com/tosin2013/dddhexagonalworkshop.git`
5. **Devfile Path**: `devfile-complete.yaml`
6. **Create**: Click "Create & Open"

### Expected Startup Timeline
| Time | Service | Status | Notes |
|------|---------|--------|-------|
| **0-30s** | Java 21 Container | ✅ Ready | VS Code interface loads |
| **30-60s** | PostgreSQL | 🟡 Initializing | Database setup in progress |
| **60-90s** | PostgreSQL | ✅ Ready | Database available |
| **90-120s** | Kafka | 🟡 Starting | Broker initialization |
| **120s+** | All Services | ✅ Ready | Complete environment ready |

## Step 2: Validate Environment Setup

### 2.1 Basic Environment Check

Once your workspace loads, open a terminal and run:

```bash
# Check Java version (should be 21)
java -version

# Check Maven availability
mvn -version

# Verify project structure
pwd
ls -la /projects
```

**Expected Output:**
```
$ java -version
openjdk version "21.0.x" 2024-xx-xx LTS
OpenJDK Runtime Environment (Red Hat-21.0.x.x-x) (build 21.0.x+x-LTS)
OpenJDK 64-Bit Server VM (Red Hat-21.0.x.x-x) (build 21.0.x+x-LTS, mixed mode, sharing)

$ mvn -version
Apache Maven 3.8.x (xxxxx)
Maven home: /usr/share/maven
Java version: 21.0.x, vendor: Red Hat, Inc.
```

### 2.2 Service Connectivity Validation

#### Test PostgreSQL Connection
```bash
# Test PostgreSQL connectivity (Method 2 - works without nc)
timeout 5 bash -c '</dev/tcp/localhost/5432' && echo "✅ PostgreSQL is running" || echo "❌ PostgreSQL not accessible"
```

#### Test Kafka Connection
```bash
# Test Kafka connectivity
timeout 5 bash -c '</dev/tcp/localhost/9092' && echo "✅ Kafka is running" || echo "❌ Kafka not accessible"
```

#### Combined Service Test Script
```bash
# Create comprehensive service test
cat > test-services.sh << 'EOF'
#!/bin/bash
echo "=== DDD Workshop Environment Validation ==="
echo "Timestamp: $(date)"
echo

# Test Java Environment
echo "🔧 Java Environment:"
java -version 2>&1 | head -1
mvn -version 2>&1 | head -1
echo

# Test Service Connectivity
echo "🔍 Service Connectivity:"

# Test PostgreSQL
echo -n "PostgreSQL (localhost:5432): "
if timeout 3 bash -c '</dev/tcp/localhost/5432' 2>/dev/null; then
    echo "✅ RUNNING"
else
    echo "❌ NOT ACCESSIBLE (may need more time)"
fi

# Test Kafka
echo -n "Kafka (localhost:9092): "
if timeout 3 bash -c '</dev/tcp/localhost/9092' 2>/dev/null; then
    echo "✅ RUNNING"
else
    echo "❌ NOT ACCESSIBLE (may need more time)"
fi

# Test Quarkus port availability
echo -n "Quarkus (localhost:8080): "
if timeout 3 bash -c '</dev/tcp/localhost/8080' 2>/dev/null; then
    echo "✅ RUNNING"
else
    echo "⚪ AVAILABLE (ready for application)"
fi

echo
echo "=== Validation Complete ==="
EOF

chmod +x test-services.sh
./test-services.sh
```

**Expected Successful Output:**
```
=== DDD Workshop Environment Validation ===
Timestamp: Sun Aug  4 14:30:00 UTC 2025

🔧 Java Environment:
openjdk version "21.0.x" 2024-xx-xx LTS
Apache Maven 3.8.x (xxxxx)

🔍 Service Connectivity:
PostgreSQL (localhost:5432): ✅ RUNNING
Kafka (localhost:9092): ✅ RUNNING
Quarkus (localhost:8080): ⚪ AVAILABLE (ready for application)

=== Validation Complete ===
```

### 2.3 Workshop Module Validation

#### Test Module 01 Build
```bash
# Navigate to Module 01
cd /projects/dddhexagonalworkshop/01-End-to-End-DDD/module-01-code

# Verify pom.xml exists
ls -la pom.xml

# Test compilation with Java 21
./mvnw clean compile -DskipTests
```

**Expected Output:**
```
[INFO] BUILD SUCCESS
[INFO] Total time: 15.xxx s
[INFO] Finished at: 2025-08-04T14:30:00Z
```

#### Test Database and Messaging Integration
```bash
# Start Quarkus development mode (tests all integrations)
./mvnw quarkus:dev -Dquarkus.http.host=0.0.0.0
```

**Expected Startup Messages:**
```
__  ____  __  _____   ___  __ ____  ____
 --/ __ \/ / / / _ | / _ \/ //_/ / / / __/
 -/ /_/ / /_/ / __ |/ , _/ ,< / /_/ /\ \
--\___\_\____/_/ |_/_/|_/_/|_|\____/___/

INFO  [io.quarkus] (Quarkus Main Thread) ddd-attendees 0.0.1-SNAPSHOT on JVM (powered by Quarkus 3.23.0) started in 3.456s. Listening on: http://0.0.0.0:8080
INFO  [io.quarkus] (Quarkus Main Thread) Profile dev activated. Live Coding activated.
INFO  [io.quarkus] (Quarkus Main Thread) Installed features: [hibernate-orm, hibernate-orm-panache, kafka-client, ...]
```

#### Test Application Health
```bash
# In a new terminal (Ctrl+Shift+` to open new terminal)
curl http://localhost:8080/q/health

# Expected response:
# {"status":"UP","checks":[...]}
```

## Step 3: Troubleshooting Common Issues

### Issue 1: Services Not Ready
**Symptoms:**
```
PostgreSQL (localhost:5432): ❌ NOT ACCESSIBLE
Kafka (localhost:9092): ❌ NOT ACCESSIBLE
```

**Solution:**
```bash
# Wait longer for services to initialize (can take 2-3 minutes)
echo "Waiting for services to start..."
sleep 60

# Re-run validation
./test-services.sh
```

### Issue 2: Maven Build Failures
**Symptoms:**
```
[ERROR] Failed to execute goal org.apache.maven.plugins:maven-compiler-plugin
```

**Solution:**
```bash
# Verify Java 21 is being used
java -version
echo $JAVA_HOME

# Clean and retry build
./mvnw clean
./mvnw compile -DskipTests -X  # -X for debug output
```

### Issue 3: Quarkus Startup Failures
**Symptoms:**
```
ERROR: Connection to localhost:5432 refused
ERROR: Connection to node -1 (localhost:9092) could not be established
```

**Solution:**
```bash
# Verify services are running first
./test-services.sh

# Check application.properties configuration
cat src/main/resources/application.properties | grep -E "(datasource|kafka)"

# If services are running, try starting Quarkus again
./mvnw quarkus:dev -Dquarkus.http.host=0.0.0.0
```

### Issue 4: Network Tools Missing
**Symptoms:**
```
bash: nc: command not found
bash: netstat: command not found
```

**Solution:**
```bash
# Install network tools (optional)
microdnf update -y
microdnf install -y procps-ng net-tools nmap-ncat

# Or use the bash TCP test method (recommended)
timeout 3 bash -c '</dev/tcp/localhost/5432' && echo "PostgreSQL OK"
```

## Step 4: Workshop Readiness Checklist

Before starting workshop exercises, ensure:

- [ ] ✅ Java 21 is running and accessible
- [ ] ✅ Maven builds complete successfully
- [ ] ✅ PostgreSQL is accessible on localhost:5432
- [ ] ✅ Kafka is accessible on localhost:9092
- [ ] ✅ Module 01 compiles without errors
- [ ] ✅ Quarkus starts and shows "Live Coding activated"
- [ ] ✅ Health endpoint responds at http://localhost:8080/q/health
- [ ] ✅ All workshop modules are accessible in /projects/dddhexagonalworkshop/

## Step 5: Workshop Module Navigation

### Available Modules
```bash
# Module 01: End-to-End DDD (10 exercises)
cd /projects/dddhexagonalworkshop/01-End-to-End-DDD/module-01-code

# Module 02: Value Objects (7 exercises)
cd /projects/dddhexagonalworkshop/02-Value-Objects/module-02-code

# Module 03: Anticorruption Layer (5 exercises)
cd /projects/dddhexagonalworkshop/03-Anticorruption-Layer/module-03-code
```

### Quick Module Test
```bash
# Test each module builds successfully
for module in "01-End-to-End-DDD/module-01-code" "02-Value-Objects/module-02-code" "03-Anticorruption-Layer/module-03-code"; do
    echo "Testing $module..."
    cd "/projects/dddhexagonalworkshop/$module"
    ./mvnw clean compile -DskipTests -q
    echo "✅ $module builds successfully"
done
```

## Resource Requirements

### Per-User Workspace
- **Memory**: 1.9Gi (768Mi + 384Mi + 768Mi + overhead)
- **CPU**: 1000m (500m + 200m + 300m)
- **Storage**: 10Gi (ephemeral volumes)

### Cluster Capacity Planning
- **10 Users**: ~19Gi memory, 10 CPU cores
- **20 Users**: ~38Gi memory, 20 CPU cores
- **30 Users**: ~57Gi memory, 30 CPU cores

## Support and Troubleshooting

### Getting Help
1. **Check this guide** for common issues and solutions
2. **Run validation script** to identify specific problems
3. **Check Dev Spaces logs** in the dashboard
4. **Restart workspace** if services fail to start

### Additional Resources
- [Workshop Container Dependencies Analysis](workshop-container-dependencies.md)
- [ADR-0007: Java 21 Runtime Requirement](adrs/adr-0007-java-21-runtime-requirement.md)
- [OpenShift Dev Spaces Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces/)

## Author
Tosin Akinsoho <takinosh@redhat.com>

## Date
2025-08-04
