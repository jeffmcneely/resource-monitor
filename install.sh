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

echo ""
echo "Prerequisites:"
echo "- Python 3.8+ with venv support"
echo "- sudo privileges"
echo "- systemd-based Linux distribution"
echo ""

# Variables
SERVICE_USER="resourcemonitor"
INSTALL_DIR="/opt/resourcemonitor"
CONFIG_DIR="/etc/resourcemonitor"
SERVICE_FILE="resourcemonitor.service"
LOG_FILE="/var/log/resourcemonitor.log"
VENV_DIR="$INSTALL_DIR/.venv"

# Create service user
echo "Creating service user..."
sudo useradd -r -s /bin/false $SERVICE_USER 2>/dev/null || echo "User $SERVICE_USER already exists"

# Check Python 3 installation
echo "Checking Python 3 installation..."
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is not installed. Please install Python 3.8+ first."
    exit 1
fi

if ! command -v python3 -m venv &> /dev/null; then
    echo "Error: python3-venv is not available. Please install it:"
    echo "Ubuntu/Debian: sudo apt install python3-venv"
    echo "RHEL/CentOS: sudo yum install python3-venv"
    exit 1
fi

echo "Python 3 and venv support confirmed."

# Create directories
echo "Creating directories..."
sudo mkdir -p $INSTALL_DIR
sudo mkdir -p $CONFIG_DIR

# Copy application files
echo "Installing application files..."
sudo cp resource_monitor.py $INSTALL_DIR/
sudo cp requirements.txt $INSTALL_DIR/

# Create Python virtual environment
echo "Creating Python virtual environment..."
sudo python3 -m venv $VENV_DIR
sudo chown -R $SERVICE_USER:$SERVICE_USER $INSTALL_DIR

# Install Python dependencies in virtual environment
echo "Installing Python dependencies in virtual environment..."
sudo -u $SERVICE_USER $VENV_DIR/bin/pip install --upgrade pip
sudo -u $SERVICE_USER $VENV_DIR/bin/pip install -r $INSTALL_DIR/requirements.txt

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
echo "Installation Summary:"
echo "- Service user: $SERVICE_USER"
echo "- Install directory: $INSTALL_DIR"
echo "- Virtual environment: $VENV_DIR"
echo "- Configuration: $CONFIG_DIR/config"
echo "- Log file: $LOG_FILE"
echo ""
echo "Next steps:"
echo "1. Edit $CONFIG_DIR/config with your configuration"
echo "2. Enable and start the service:"
echo "   sudo systemctl enable resourcemonitor"
echo "   sudo systemctl start resourcemonitor"
echo "3. Check status: sudo systemctl status resourcemonitor"
echo "4. View logs: sudo journalctl -u resourcemonitor -f"
