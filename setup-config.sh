#!/bin/bash

# Configuration setup script for Resource Monitor
# This script helps create the host configuration file for Docker deployment

set -e

CONFIG_DIR="/etc/resourcemonitor"
CONFIG_FILE="$CONFIG_DIR/config"

echo "Setting up Resource Monitor configuration..."

# Check if running with sudo
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Create configuration directory
echo "Creating configuration directory: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR"

# Check if config file already exists
if [[ -f "$CONFIG_FILE" ]]; then
    echo "Configuration file already exists at: $CONFIG_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing configuration file."
        exit 0
    fi
fi

# Prompt for configuration values
echo ""
echo "Please provide the following configuration values:"
echo ""

# S3 Bucket Name (required)
while true; do
    read -p "S3 Bucket Name (required, must end with --ZONE--x-s3): " S3_BUCKET_NAME
    if [[ -n "$S3_BUCKET_NAME" ]]; then
        if [[ "$S3_BUCKET_NAME" =~ --[a-z0-9-]+--x-s3$ ]]; then
            break
        else
            echo "Error: Bucket name must be a valid S3 Express One Zone format (ending with --ZONE--x-s3)"
        fi
    else
        echo "Error: S3 Bucket Name is required"
    fi
done

# AWS Region (optional)
read -p "AWS Region (optional, press Enter for us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

# AWS Credentials (optional)
echo ""
echo "AWS Credentials (optional - leave blank if using IAM roles):"
read -p "AWS Access Key ID: " AWS_ACCESS_KEY_ID
if [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
    read -s -p "AWS Secret Access Key: " AWS_SECRET_ACCESS_KEY
    echo ""
fi

# Create configuration file
echo ""
echo "Creating configuration file: $CONFIG_FILE"

cat > "$CONFIG_FILE" << EOF
# Environment configuration for Resource Monitor
# Created on $(date)

# Required: S3 bucket name (include the full Express One Zone suffix)
S3_BUCKET_NAME=$S3_BUCKET_NAME

# Optional: AWS region
AWS_DEFAULT_REGION=$AWS_REGION

# Optional: AWS credentials (not needed if using IAM roles)
EOF

if [[ -n "$AWS_ACCESS_KEY_ID" ]]; then
    cat >> "$CONFIG_FILE" << EOF
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
EOF
else
    cat >> "$CONFIG_FILE" << EOF
# AWS_ACCESS_KEY_ID=your_access_key
# AWS_SECRET_ACCESS_KEY=your_secret_key
EOF
fi

# Set appropriate permissions
chmod 644 "$CONFIG_FILE"

echo ""
echo "Configuration file created successfully!"
echo "File location: $CONFIG_FILE"
echo ""
echo "You can now run the Docker container with:"
echo "  docker-compose up -d"
echo ""
echo "To edit the configuration later:"
echo "  sudo nano $CONFIG_FILE"
