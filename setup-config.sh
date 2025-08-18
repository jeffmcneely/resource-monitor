#!/bin/bash

# Setup script for Resource Monitor configuration
set -e

echo "Resource Monitor Configuration Setup"
echo "===================================="
echo
echo "This script will create the configuration file for the Resource Monitor service."
echo "The S3 bucket name is now managed through AWS SSM Parameter Store."
echo

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Error: This script must be run as root (use sudo)"
    exit 1
fi

# Create config directory
mkdir -p /etc/resourcemonitor

# Get configuration values
echo "Please provide the following configuration values:"
echo

# Upload frequency
read -p "Upload frequency in seconds (optional, press Enter for 60): " UPLOAD_FREQUENCY
UPLOAD_FREQUENCY=${UPLOAD_FREQUENCY:-60}

# Hostname override
read -p "Custom hostname (optional, press Enter for system hostname): " HOSTNAME_OVERRIDE
if [ -z "$HOSTNAME_OVERRIDE" ]; then
    HOSTNAME_OVERRIDE=$(hostname)
fi

# AWS Region
read -p "AWS Region (optional, press Enter for us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

# Create configuration file
cat > /etc/resourcemonitor/config << EOF
# Resource Monitor Configuration
# S3 bucket name is retrieved from SSM Parameter Store: /resourcemonitor/config/bucketName

# Optional: Upload frequency in seconds (default: 60)
UPLOAD_FREQUENCY_SECONDS=$UPLOAD_FREQUENCY

# Optional: Custom hostname (default: system hostname)
HOSTNAME_OVERRIDE=$HOSTNAME_OVERRIDE

# Optional: AWS region
AWS_DEFAULT_REGION=$AWS_REGION

# Optional: Log file location
LOG_FILE=/var/log/resourcemonitor/resourcemonitor.log

# Optional: Data directory for temporary files
DATA_DIR=/var/lib/resourcemonitor/data
EOF

# Set proper permissions
chmod 644 /etc/resourcemonitor/config

# Create log and data directories
mkdir -p /var/log/resourcemonitor
mkdir -p /var/lib/resourcemonitor/data

echo
echo "Configuration file created successfully!"
echo "File location: /etc/resourcemonitor/config"
echo
echo "Configuration summary:"
echo "  Upload Frequency: ${UPLOAD_FREQUENCY}s"
echo "  Hostname: $HOSTNAME_OVERRIDE"
echo "  AWS Region: $AWS_REGION"
echo "  S3 Bucket: Retrieved from SSM Parameter Store"
echo
echo "Important: Ensure your EC2 instance has the ResourceMonitorRole attached"
echo "and the SSM parameter '/resourcemonitor/config/bucketName' is configured."
echo
echo "To deploy the IAM role and SSM parameter, use:"
echo "  aws cloudformation deploy --template-file resource_monitor_s3_role.yaml \\"
echo "    --stack-name resource-monitor-role \\"
echo "    --parameter-overrides BucketName=your-bucket-name \\"
echo "    --capabilities CAPABILITY_NAMED_IAM"
EOF