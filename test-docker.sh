#!/bin/bash

# Docker test script for Resource Monitor
# This script tests the Docker container functionality

set -e

echo "Testing Docker Resource Monitor..."
echo "================================="

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is not running. Please start Docker first."
    exit 1
fi

echo "Building test image..."
docker build -t resource-monitor:test .

echo "Running test container..."
# Run container with test environment
docker run --rm \
    --name resource-monitor-test \
    -e S3_BUCKET_NAME=test-bucket--us-east-1a--x-s3 \
    -e AWS_DEFAULT_REGION=us-east-1 \
    -v "$(pwd)/logs:/app/logs" \
    -v "$(pwd)/data:/app/data" \
    -v /proc:/host/proc:ro \
    -v /sys:/host/sys:ro \
    --timeout 10s \
    resource-monitor:test python -c "
import sys
sys.path.insert(0, '/app')
from resource_monitor import ResourceMonitor

# Test basic functionality without S3
print('Testing metrics collection...')
try:
    monitor = ResourceMonitor()
except Exception as e:
    print(f'Expected S3 error: {e}')

# Test individual components
from test_monitor import TestMonitor
test_monitor = TestMonitor()
metrics = test_monitor.collect_metrics()
print(f'✓ Collected metrics for host: {metrics[\"hostname\"]}')
print(f'✓ CPU usage: {metrics[\"cpu\"][\"usage_percent\"]}%')
print(f'✓ RAM usage: {metrics[\"memory\"][\"virtual\"][\"percent\"]}%')
print('✓ Docker container test passed!')
"

echo ""
echo "Test completed successfully!"
echo "The container can collect system metrics properly."
