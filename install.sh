#!/bin/bash

# Resource Monitor Installation Script
# This script automates the installation and setup of the resource monitor

set -e

echo "Installing Resource Monitor..."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root directly. Use sudo for individual commands."
   exit 1
fi

# Variables
SERVICE_USER="resourcemonitor"
INSTALL_DIR="/opt/resourcemonitor"
CONFIG_DIR="/etc/resourcemonitor"
SERVICE_FILE="resourcemonitor.service"
LOG_FILE="/var/log/resourcemonitor.log"

# Create service user
echo "Creating service user..."
sudo useradd -r -s /bin/false $SERVICE_USER 2>/dev/null || echo "User $SERVICE_USER already exists"

# Create directories
echo "Creating directories..."
sudo mkdir -p $INSTALL_DIR
sudo mkdir -p $CONFIG_DIR

# Copy application files
echo "Installing application files..."
sudo cp resource_monitor.py $INSTALL_DIR/
sudo cp requirements.txt $INSTALL_DIR/
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

# Install Python dependencies
echo "Installing Python dependencies..."
sudo pip3 install -r requirements.txt

# Create log file
echo "Setting up logging..."
sudo touch $LOG_FILE
sudo chown $SERVICE_USER:$SERVICE_USER $LOG_FILE

# Install systemd service
echo "Installing systemd service..."
sudo cp $SERVICE_FILE /etc/systemd/system/
sudo systemctl daemon-reload

# Create config file if it doesn't exist
if [ ! -f "$CONFIG_DIR/config" ]; then
    echo "Creating configuration file..."
    sudo cp .env.example $CONFIG_DIR/config
    echo "Please edit $CONFIG_DIR/config with your S3 bucket name and AWS credentials"
fi

echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit $CONFIG_DIR/config with your configuration"
echo "2. Deploy the CloudFormation stack: sam deploy --config-file samconfig.toml"
echo "3. Enable and start the service:"
echo "   sudo systemctl enable resourcemonitor"
echo "   sudo systemctl start resourcemonitor"
echo "4. Check status: sudo systemctl status resourcemonitor"
