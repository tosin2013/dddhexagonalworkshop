#!/bin/bash
# Golden Path Devfile Validation Script
# Based on ADR-0003: Inner/Outer Loop Separation Strategy
# Research Finding: Standardized devfile prevents configuration drift

set -e

DEVFILE_PATH="${1:-devfile.yaml}"
TEMPLATE_PATH="$(dirname "$0")/devfile-template.yaml"

echo "=== Golden Path Devfile Validation ==="
echo "Validating: $DEVFILE_PATH"
echo "Template: $TEMPLATE_PATH"
echo

# Check if devfile exists
if [ ! -f "$DEVFILE_PATH" ]; then
    echo "❌ ERROR: Devfile not found at $DEVFILE_PATH"
    exit 1
fi

# Check if template exists
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "❌ ERROR: Golden path template not found at $TEMPLATE_PATH"
    exit 1
fi

# Validation checks
VALIDATION_ERRORS=0

echo "🔍 Checking Golden Path version..."
if grep -q "GOLDEN_PATH_VERSION.*1.0.0" "$DEVFILE_PATH"; then
    echo "✅ Golden Path version is correct"
else
    echo "❌ Golden Path version missing or incorrect"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

echo "🔍 Checking sidecar pattern configuration (ADR-0002)..."
if grep -q "POSTGRES_SERVICE_HOST.*localhost" "$DEVFILE_PATH"; then
    echo "✅ PostgreSQL sidecar configuration is correct"
else
    echo "❌ PostgreSQL sidecar configuration is incorrect (should be localhost)"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if grep -q "KAFKA_SERVICE_HOST.*localhost" "$DEVFILE_PATH"; then
    echo "✅ Kafka sidecar configuration is correct"
else
    echo "❌ Kafka sidecar configuration is incorrect (should be localhost)"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

echo "🔍 Checking sidecar containers presence..."
if grep -q "name: postgresql" "$DEVFILE_PATH" && grep -q "container:" "$DEVFILE_PATH"; then
    echo "✅ PostgreSQL sidecar container is present"
else
    echo "❌ PostgreSQL sidecar container is missing"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if grep -q "name: kafka" "$DEVFILE_PATH" && grep -q "container:" "$DEVFILE_PATH"; then
    echo "✅ Kafka sidecar container is present"
else
    echo "❌ Kafka sidecar container is missing"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

echo "🔍 Checking resource configurations..."
if grep -q "QUARKUS_MEMORY_REQUEST.*512Mi" "$DEVFILE_PATH"; then
    echo "✅ Quarkus memory request is research-validated"
else
    echo "❌ Quarkus memory request is not optimized"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if grep -q "QUARKUS_MEMORY_LIMIT.*1Gi" "$DEVFILE_PATH"; then
    echo "✅ Quarkus memory limit is research-validated"
else
    echo "❌ Quarkus memory limit is not optimized"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

echo "🔍 Checking required validation commands..."
if grep -q "validate-golden-path" "$DEVFILE_PATH"; then
    echo "✅ Golden path validation command is present"
else
    echo "❌ Golden path validation command is missing"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

if grep -q "check-infrastructure-connectivity" "$DEVFILE_PATH"; then
    echo "✅ Infrastructure connectivity check is present"
else
    echo "❌ Infrastructure connectivity check is missing"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

echo
echo "=== Validation Summary ==="
if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo "🎉 SUCCESS: Devfile conforms to Golden Path requirements"
    echo "✅ Configuration drift prevention: ACTIVE"
    echo "✅ Research-validated settings: APPLIED"
    echo "✅ Service connectivity: STANDARDIZED"
    exit 0
else
    echo "❌ FAILED: $VALIDATION_ERRORS validation errors found"
    echo "🔧 Please fix the errors above to conform to Golden Path requirements"
    echo "📖 Reference: ADR-0003 (Inner/Outer Loop Separation Strategy)"
    echo "🔬 Research Finding: Standardization critical for <5% failure rate"
    exit 1
fi
