#!/bin/bash

# Docker-based Resource Monitor Installation Script
# This script sets up the resource monitor to run as a Docker container

set -e

echo "Installing Resource Monitor (Docker version)..."
echo "=============================================="

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed. Please install Docker first:"
    echo "https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null 2>&1; then
    echo "Error: Docker Compose is not installed. Please install Docker Compose first:"
    echo "https://docs.docker.com/compose/install/"
    exit 1
fi

echo "Docker and Docker Compose confirmed."

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Warning: Running as root. Consider running as a regular user with Docker permissions."
fi

# Create necessary directories
echo "Creating directories..."
mkdir -p logs data

# Setup configuration
echo "Setting up configuration..."
echo "You need to create the host configuration file at /etc/resourcemonitor/config"
echo ""
read -p "Do you want to run the configuration setup script now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    if [[ $EUID -eq 0 ]]; then
        ./setup-config.sh
    else
        echo "Running configuration setup with sudo..."
        sudo ./setup-config.sh
    fi
else
    echo "You can run the configuration setup later with: sudo ./setup-config.sh"
    echo "Or manually create /etc/resourcemonitor/config with your S3 bucket settings"
fi

# Build the Docker image
echo "Building Docker image..."
docker build -t resource-monitor:latest .

# Check if container is already running
if docker ps | grep -q resource-monitor; then
    echo "Stopping existing container..."
    docker stop resource-monitor
    docker rm resource-monitor
fi

echo ""
echo "Installation complete!"
echo ""
echo "Installation Summary:"
echo "- Docker image: resource-monitor:latest"
echo "- Logs directory: ./logs"
echo "- Data directory: ./data"
echo "- Configuration: /etc/resourcemonitor/config"
echo ""
echo "Next steps:"
echo "1. Ensure /etc/resourcemonitor/config is properly configured"
echo "2. Start the container:"
echo "   docker-compose up -d"
echo "3. Check logs:"
echo "   docker-compose logs -f"
echo "4. Check status:"
echo "   docker-compose ps"
echo ""
echo "Management commands:"
echo "- Start: docker-compose up -d"
echo "- Stop: docker-compose down"
echo "- Logs: docker-compose logs -f resource-monitor"
echo "- Restart: docker-compose restart resource-monitor"
