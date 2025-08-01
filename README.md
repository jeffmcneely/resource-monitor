# System Resource Monitor

A Python-based system monitoring tool that continuously tracks CPU usage, NVIDIA GPU metrics, system RAM, GPU VRAM, and CPU temperature. The collected data is stored in JSON format and uploaded to an AWS S3 Express One Zone bucket every second.

## Features

- **CPU Monitoring**: Usage percentage, per-core usage, frequency, temperature
- **Memory Monitoring**: RAM usage, swap usage, detailed memory statistics
- **GPU Monitoring**: NVIDIA GPU utilization, VRAM usage, temperature, power consumption, fan speed
- **Real-time Data**: Collects metrics every second
- **Cloud Storage**: Automatic upload to S3 Express One Zone bucket
- **Systemd Integration**: Runs as a system service
- **Infrastructure as Code**: CloudFormation template for AWS resources

### Option 2: Native Installation (Linux/systemd)

For traditional systemd-based installations on Linux servers.

#### Prerequisites

### System Requirements
- **Python 3.8+** with `venv` module support
- **Linux system** with systemd support (Ubuntu 18.04+, Debian 10+, RHEL 8+, etc.)
- **sudo privileges** for system installation
- **AWS CLI** configured with appropriate credentials

### Python Dependencies Installation
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-venv python3-pip

# RHEL/CentOS/Fedora
sudo yum install python3 python3-venv python3-pip
# or for newer versions:
sudo dnf install python3 python3-venv python3-pip
```

### Optional Components
- **NVIDIA GPU drivers and CUDA** (for GPU monitoring)
- **AWS SAM CLI** (for infrastructure deployment)

#### Native Installation Steps

The Resource Monitor can be deployed in two ways:

### Option 1: Docker Deployment (Recommended)

Docker provides better isolation, easier deployment, and consistent environments.

#### 1. Prerequisites
```bash
# Install Docker and Docker Compose
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose

# Add user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

#### 2. Quick Start
```bash
# Clone and setup
git clone <repository-url>
cd resourcemonitor

# Run the Docker installation script
./install-docker.sh

# Edit configuration
nano .env

# Start the container
docker-compose up -d
```

#### 3. Container Management
```bash
# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Stop container
docker-compose down

# Restart container
docker-compose restart resource-monitor

# Update and restart
docker-compose build --no-cache
docker-compose up -d

# For GPU monitoring (requires NVIDIA Docker runtime)
docker-compose -f docker-compose.gpu.yml up -d
```

### Option 2: Native Installation (Linux/systemd)

### 1. Clone and Setup

```bash
git clone <repository-url>
cd resourcemonitor
```

### 2. Install Python Dependencies

```bash
# Create virtual environment
python3 -m venv .venv

# Activate virtual environment
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 3. Configure Environment Variables

Create `/etc/resourcemonitor/config` file:

```bash
sudo mkdir -p /etc/resourcemonitor
sudo tee /etc/resourcemonitor/config << EOF
S3_BUCKET_NAME=your-bucket-name--us-east-1a--x-s3
AWS_DEFAULT_REGION=us-east-1
EOF
```

### 4. Deploy AWS Infrastructure

#### Using AWS SAM:

```bash
# Install AWS SAM CLI
pip install aws-sam-cli

# Deploy the CloudFormation stack
sam deploy --config-file samconfig.toml
```

#### Using AWS CLI:

```bash
aws cloudformation deploy \
  --template-file s3-express-bucket.yaml \
  --stack-name resource-monitor-s3 \
  --parameter-overrides BucketName=resource-monitor-data AvailabilityZone=us-east-1a \
  --capabilities CAPABILITY_NAMED_IAM
```

### 5. Setup System Service

```bash
# Run the automated installation script
./install.sh

# The script will:
# - Create dedicated user
# - Set up virtual environment at /opt/resourcemonitor/.venv
# - Install Python dependencies in the virtual environment
# - Configure systemd service
# - Set up logging and permissions
```

**Manual installation steps (if needed):**

```bash
# Create dedicated user
sudo useradd -r -s /bin/false resourcemonitor

# Copy application files
sudo mkdir -p /opt/resourcemonitor
sudo cp resource_monitor.py /opt/resourcemonitor/
sudo cp requirements.txt /opt/resourcemonitor/

# Create virtual environment
sudo python3 -m venv /opt/resourcemonitor/.venv
sudo chown -R resourcemonitor:resourcemonitor /opt/resourcemonitor

# Install Python dependencies in virtual environment
sudo -u resourcemonitor /opt/resourcemonitor/.venv/bin/pip install --upgrade pip
sudo -u resourcemonitor /opt/resourcemonitor/.venv/bin/pip install -r /opt/resourcemonitor/requirements.txt

# Install systemd service
sudo cp resourcemonitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable resourcemonitor
sudo systemctl start resourcemonitor
```

## Usage

### Docker Deployment

```bash
# Start monitoring
docker-compose up -d

# View real-time logs
docker-compose logs -f resource-monitor

# Check container status
docker-compose ps

# Stop monitoring
docker-compose down
```

#### GPU Monitoring with Docker

For systems with NVIDIA GPUs, use the GPU-enabled compose file:

```bash
# Prerequisites: Install NVIDIA Container Toolkit
# Ubuntu/Debian:
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Start with GPU support
docker-compose -f docker-compose.gpu.yml up -d
```

#### Docker Troubleshooting

```bash
# Test Docker container
./test-docker.sh

# Check container logs
docker logs resource-monitor

# Access container shell for debugging
docker exec -it resource-monitor /bin/bash

# Rebuild container after changes
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Environment Variables (Docker)

Set these in your `.env` file:

- `S3_BUCKET_NAME`: Name of the S3 Express One Zone bucket (required)
- `AWS_DEFAULT_REGION`: AWS region (optional, defaults to us-east-1)
- `AWS_ACCESS_KEY_ID`: AWS access key (optional if using IAM roles)
- `AWS_SECRET_ACCESS_KEY`: AWS secret key (optional if using IAM roles)
- `LOG_FILE`: Log file path (optional, defaults to /app/logs/resourcemonitor.log)
- `DATA_DIR`: Data directory path (optional, defaults to /app/data)

### Native Installation (systemd)

### Manual Execution

```bash
# Set environment variable
export S3_BUCKET_NAME=your-bucket-name--us-east-1a--x-s3

# Activate virtual environment (for development)
source .venv/bin/activate

# Run the monitor
python resource_monitor.py
```

### Service Management

```bash
# Check service status
sudo systemctl status resourcemonitor

# View logs
sudo journalctl -u resourcemonitor -f

# Stop the service
sudo systemctl stop resourcemonitor

# Restart the service
sudo systemctl restart resourcemonitor
```

## Configuration

### Environment Variables

- `S3_BUCKET_NAME`: Name of the S3 Express One Zone bucket (required)
- `AWS_DEFAULT_REGION`: AWS region (optional, defaults to us-east-1)
- `AWS_ACCESS_KEY_ID`: AWS access key (optional if using IAM roles)
- `AWS_SECRET_ACCESS_KEY`: AWS secret key (optional if using IAM roles)

### AWS Credentials

The application supports multiple authentication methods:

1. **IAM Roles** (recommended for EC2 instances)
2. **Environment variables**
3. **AWS credentials file** (`~/.aws/credentials`)
4. **Instance metadata** (for EC2 instances)

## Data Format

The monitoring data is stored in JSON format with the following structure:

```json
{
  "timestamp": "2025-07-29T12:00:00Z",
  "hostname": "server-01",
  "cpu": {
    "usage_percent": 25.4,
    "usage_per_core": [20.1, 30.7, 22.3, 28.9],
    "frequency": {
      "current": 2400.0,
      "min": 800.0,
      "max": 3200.0
    },
    "temperatures": [
      {
        "sensor": "coretemp_Core 0",
        "temperature": 45.0,
        "high": 100.0,
        "critical": 105.0
      }
    ]
  },
  "memory": {
    "virtual": {
      "total": 16777216000,
      "used": 8388608000,
      "percent": 50.0
    },
    "swap": {
      "total": 2147483648,
      "used": 0,
      "percent": 0.0
    }
  },
  "gpu": [
    {
      "index": 0,
      "name": "NVIDIA GeForce RTX 4080",
      "memory": {
        "total": 17179869184,
        "used": 2147483648,
        "percent": 12.5
      },
      "utilization": {
        "gpu": 15,
        "memory": 12
      },
      "temperature": 42,
      "power_usage_watts": 45.2,
      "fan_speed_percent": 30
    }
  ]
}
```

## Infrastructure

### S3 Express One Zone Bucket

The CloudFormation template creates:

- **S3 Express One Zone bucket** for high-performance data storage
- **Public read access** for easy data retrieval
- **Lifecycle policies** to automatically delete old data (30 days)
- **IAM roles and policies** for secure access
- **Access logging** to a separate standard S3 bucket

### Security Features

- **Minimal privileges**: Service runs with restricted permissions
- **Secure systemd configuration**: NoNewPrivileges, PrivateTmp, ProtectSystem
- **IAM roles**: Uses AWS IAM for secure S3 access
- **Encryption**: S3 bucket uses AES-256 encryption

## Monitoring and Logging

- **Application logs**: `/var/log/resourcemonitor.log`
- **Systemd logs**: `journalctl -u resourcemonitor`
- **S3 access logs**: Stored in the access logs bucket

## Troubleshooting

### Common Issues

1. **Missing NVIDIA drivers**: GPU monitoring will be disabled
2. **AWS credentials**: Ensure proper AWS configuration
3. **S3 bucket permissions**: Verify upload permissions
4. **Systemd service**: Check logs with `journalctl -u resourcemonitor`

### Debugging

```bash
# Test S3 connectivity
aws s3 ls s3://your-bucket-name--us-east-1a--x-s3/

# Check Python dependencies (with virtual environment activated)
python -c "import psutil, boto3, pynvml; print('All dependencies available')"

# Or check system installation dependencies
/opt/resourcemonitor/.venv/bin/python -c "import psutil, boto3, pynvml; print('All dependencies available')"

# Test monitoring script
source .venv/bin/activate  # For development
python resource_monitor.py
```

## Performance Considerations

- **S3 Express One Zone**: Provides single-digit millisecond latency
- **Local file cleanup**: Temporary files are automatically removed
- **Memory efficient**: Minimal memory footprint
- **Error resilience**: Continues monitoring even after transient errors

## Cost Optimization

- **Lifecycle policies**: Automatic deletion of old metrics (30 days)
- **Express One Zone**: Cost-effective for high-frequency access
- **Efficient data format**: Compact JSON structure

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs
3. Open an issue on the repository
