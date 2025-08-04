# Troubleshooting Guide
## DDD Hexagonal Architecture Workshop - OpenShift Dev Spaces

This comprehensive troubleshooting guide helps you diagnose and resolve common issues when running the DDD Hexagonal Architecture Workshop in OpenShift Dev Spaces.

## 🚨 Quick Diagnostic Commands

Before diving into specific issues, run these commands to get an overview:

```bash
# Check all environment variables
env | grep -E "(QUARKUS|KAFKA|POSTGRES)" | sort

# Test network connectivity (use devfile validation commands)
timeout 3 bash -c '</dev/tcp/localhost/5432' && echo "PostgreSQL OK"
timeout 3 bash -c '</dev/tcp/localhost/9092' && echo "Kafka OK"

# Check container processes
ps aux | grep -E "(postgres|kafka|java)"

# Verify workspace setup
java -version && mvn -version
```

## 🔧 Common Issues and Solutions

### 1. Workspace Startup Issues

#### Issue: Workspace Fails to Start
**Symptoms:**
- Workspace creation hangs
- Containers fail to initialize
- Timeout errors during startup

**Diagnosis:**
```bash
# Check workspace status in OpenShift console
oc get pods -l controller.devfile.io/devworkspace_name=<workspace-name>

# Check events
oc get events --sort-by='.lastTimestamp' | tail -20

# Check resource quotas
oc describe resourcequota -n <namespace>
```

**Solutions:**
1. **Resource Constraints:**
   ```bash
   # Check available resources
   oc describe nodes | grep -A 5 "Allocated resources"
   
   # Reduce resource limits in devfile.yaml
   variables:
     QUARKUS_MEMORY_LIMIT: "512Mi"
     POSTGRES_MEMORY_LIMIT: "256Mi"
     KAFKA_MEMORY_LIMIT: "512Mi"
   ```

2. **Image Pull Issues:**
   ```bash
   # Check image pull status
   oc describe pod <pod-name> | grep -A 10 "Events"
   
   # Verify image registry access
   oc get secrets | grep pull
   ```

3. **Storage Issues:**
   ```bash
   # Check storage classes
   oc get storageclass
   
   # Check PVC status
   oc get pvc -n <namespace>
   ```

#### Issue: Slow Startup Times
**Symptoms:**
- Containers take longer than 5 minutes to start
- Maven dependency resolution is slow
- Application startup is delayed

**Solutions:**
1. **Optimize Maven Cache:**
   ```bash
   # Pre-populate Maven cache
   cd /projects/dddhexagonalworkshop/01-End-to-End-DDD/module-01-code
   ./mvnw dependency:go-offline
   ```

2. **Adjust Startup Sequence:**
   ```yaml
   # In devfile.yaml, increase timeouts
   events:
     preStart:
       - "wait-for-postgresql"  # Increase timeout
       - "wait-for-kafka"       # Increase timeout
   ```

### 2. Database Connectivity Issues

#### Issue: PostgreSQL Connection Failures
**Symptoms:**
- Quarkus fails to start with database errors
- Connection timeout errors
- Authentication failures

**Diagnosis:**
```bash
# Check PostgreSQL container status
oc get pods -l component=postgresql

# Test port connectivity
nc -z localhost 5432

# Test database connection
PGPASSWORD=workshop psql -h localhost -p 5432 -U attendee -d conference -c "SELECT 1;"

# Check PostgreSQL logs
oc logs -f deployment/ddd-workshop-postgresql
```

**Solutions:**
1. **Container Not Ready:**
   ```bash
   # Wait for PostgreSQL to be ready
   ./scripts/health-checks/postgresql-health.sh
   
   # Check readiness probe
   oc describe pod <postgresql-pod> | grep -A 5 "Readiness"
   ```

2. **Network Issues:**
   ```bash
   # Check service endpoints
   oc get endpoints ddd-workshop-postgresql
   
   # Test internal networking
   oc exec -it <quarkus-pod> -- nc -z localhost 5432
   ```

3. **Configuration Issues:**
   ```bash
   # Verify environment variables
   oc exec -it <postgresql-pod> -- env | grep POSTGRESQL
   
   # Check configuration
   oc get configmap ddd-workshop-postgresql-config -o yaml
   ```

#### Issue: Database Schema Problems
**Symptoms:**
- Tables not created
- Schema generation errors
- Data persistence issues

**Solutions:**
1. **Force Schema Recreation:**
   ```properties
   # In application.properties
   quarkus.hibernate-orm.database.generation=drop-and-create
   quarkus.hibernate-orm.sql-load-script=import.sql
   ```

2. **Check Hibernate Logs:**
   ```properties
   # Enable SQL logging
   quarkus.hibernate-orm.log.sql=true
   quarkus.log.category."org.hibernate.SQL".level=DEBUG
   ```

### 3. Kafka Connectivity Issues

#### Issue: Kafka Broker Not Available
**Symptoms:**
- Kafka connection timeouts
- Message publishing failures
- Consumer group errors

**Diagnosis:**
```bash
# Check Kafka container status
oc get pods -l component=kafka

# Test Kafka connectivity
nc -z localhost 9092

# Check Kafka logs
oc logs -f deployment/ddd-workshop-kafka

# Test broker API (if tools available)
kafka-broker-api-versions.sh --bootstrap-server localhost:9092
```

**Solutions:**
1. **Startup Sequence Issues:**
   ```bash
   # Check service connectivity
   timeout 3 bash -c '</dev/tcp/localhost/9092' && echo "Kafka OK"

   # Check startup events (if using OpenShift)
   oc get events | grep kafka
   ```

2. **Configuration Problems:**
   ```bash
   # Verify Kafka configuration
   oc get configmap ddd-workshop-kafka-config -o yaml
   
   # Check environment variables
   oc exec -it <kafka-pod> -- env | grep KAFKA
   ```

3. **Topic Creation Issues:**
   ```bash
   # List topics (if tools available)
   kafka-topics.sh --bootstrap-server localhost:9092 --list
   
   # Create topic manually
   kafka-topics.sh --bootstrap-server localhost:9092 --create --topic attendee-registered --partitions 1 --replication-factor 1
   ```

### 4. Application Runtime Issues

#### Issue: Quarkus Application Won't Start
**Symptoms:**
- Application startup failures
- Port binding errors
- Dependency injection issues

**Diagnosis:**
```bash
# Check application logs
tail -f target/quarkus.log

# Check Java processes
ps aux | grep java

# Test port availability
netstat -tlnp | grep 8080

# Check application health
curl -s http://localhost:8080/q/health
```

**Solutions:**
1. **Port Binding Issues:**
   ```properties
   # Ensure binding to all interfaces
   quarkus.http.host=0.0.0.0
   quarkus.http.port=8080
   ```

2. **Memory Issues:**
   ```bash
   # Check memory usage
   free -h
   
   # Adjust JVM settings
   export MAVEN_OPTS="-Xmx512m -XX:MaxMetaspaceSize=256m"
   ```

3. **Dependency Issues:**
   ```bash
   # Clean and rebuild
   ./mvnw clean compile
   
   # Check for dependency conflicts
   ./mvnw dependency:tree
   ```

#### Issue: Live Reload Not Working
**Symptoms:**
- Changes not reflected automatically
- Manual restart required
- Compilation errors

**Solutions:**
1. **Enable Live Reload:**
   ```properties
   # In application.properties
   quarkus.live-reload.instrumentation=true
   ```

2. **Check File Watching:**
   ```bash
   # Verify file system events
   inotifywait -m -r src/
   ```

### 5. Network and Access Issues

#### Issue: Cannot Access Application Externally
**Symptoms:**
- Browser cannot reach application
- Route not working
- SSL/TLS errors

**Diagnosis:**
```bash
# Check OpenShift routes
oc get routes -n <namespace>

# Check service endpoints
oc get endpoints ddd-workshop-quarkus

# Test internal connectivity
oc exec -it <pod> -- curl -s http://localhost:8080/q/health
```

**Solutions:**
1. **Route Configuration:**
   ```bash
   # Check route details
   oc describe route ddd-workshop-quarkus
   
   # Test route connectivity
   curl -s https://<route-url>/q/health
   ```

2. **Service Configuration:**
   ```bash
   # Verify service configuration
   oc describe service ddd-workshop-quarkus
   
   # Check port forwarding
   oc port-forward svc/ddd-workshop-quarkus 8080:8080
   ```

### 6. Performance Issues

#### Issue: Slow Application Response
**Symptoms:**
- High response times
- Timeouts
- Resource exhaustion

**Diagnosis:**
```bash
# Check resource usage
oc top pods -n <namespace>

# Check application metrics
curl -s http://localhost:8080/q/metrics

# Monitor logs for errors
tail -f target/quarkus.log | grep ERROR
```

**Solutions:**
1. **Resource Optimization:**
   ```yaml
   # Adjust resource limits in devfile
   components:
     - name: quarkus-dev
       container:
         memoryLimit: "1Gi"
         cpuLimit: "500m"
   ```

2. **JVM Tuning:**
   ```bash
   # Optimize JVM settings
   export MAVEN_OPTS="-Xmx512m -XX:+UseG1GC -XX:MaxGCPauseMillis=100"
   ```

## 🛠️ Diagnostic Tools and Scripts

### Available Scripts

1. **Network Troubleshooting:**
   ```bash
   ./scripts/network-troubleshoot.sh
   ./scripts/network-troubleshoot.sh --postgresql
   ./scripts/network-troubleshoot.sh --kafka
   ./scripts/network-troubleshoot.sh --quarkus
   ```

2. **Health Checks:**
   ```bash
   ./scripts/health-checks/postgresql-health.sh
   ./scripts/health-checks/kafka-health.sh
   ./scripts/health-checks/quarkus-health.sh
   ```

3. **Environment Setup:**
   ```bash
   ./scripts/setup-environment.sh
   ./scripts/setup-environment.sh --test-only
   ```

4. **Service Validation:**
   ```bash
   # Check all services
   timeout 3 bash -c '</dev/tcp/localhost/5432' && echo "PostgreSQL OK"
   timeout 3 bash -c '</dev/tcp/localhost/9092' && echo "Kafka OK"
   ```

### Manual Diagnostic Commands

```bash
# Container status
oc get pods -o wide

# Resource usage
oc top pods

# Events
oc get events --sort-by='.lastTimestamp'

# Logs
oc logs -f deployment/ddd-workshop-postgresql
oc logs -f deployment/ddd-workshop-kafka
oc logs -f deployment/ddd-workshop-quarkus

# Network connectivity
oc exec -it <pod> -- nc -z localhost 5432
oc exec -it <pod> -- nc -z localhost 9092
oc exec -it <pod> -- curl -s http://localhost:8080/q/health

# Configuration
oc get configmaps -o yaml
oc get secrets -o yaml
oc describe devworkspace <workspace-name>
```

## 📞 Getting Help

### Self-Service Resources

1. **Documentation:**
   - [OpenShift Dev Spaces Guide](OPENSHIFT_DEV_SPACES.md)
   - [Deployment Guide](DEPLOYMENT_GUIDE.md)
   - [Migration Guide](MIGRATION_GUIDE.md)

2. **Automated Diagnostics:**
   ```bash
   # Run comprehensive diagnostics
   ./scripts/network-troubleshoot.sh
   ```

3. **Health Checks:**
   ```bash
   # Check all components
   curl -s http://localhost:8080/q/health || echo "Quarkus not running"
   ```

### When to Escalate

Contact support when:
- Multiple diagnostic attempts fail
- Infrastructure-level issues are suspected
- Security or compliance concerns arise
- Performance issues persist after optimization

### Support Information

- **Workshop Instructor**: Available during workshop sessions
- **Repository Issues**: https://github.com/jeremyrdavis/dddhexagonalworkshop/issues
- **Author**: Tosin Akinsoho <takinosh@redhat.com>
- **Red Hat Support**: For enterprise customers with support contracts

---

**Last Updated**: 2025-01-01  
**Version**: 1.0.0  
**Compatibility**: OpenShift 4.14+, Dev Spaces 3.8+
