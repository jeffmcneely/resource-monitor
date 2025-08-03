# System Resource Monitor

A Python-based system monitoring tool that continuously tracks CPU usage, NVIDIA GPU metrics, system RAM, GPU VRAM, and CPU temperature. The collected data is stored in JSON format and uploaded to an AWS S3 Express One Zone bucket every second.

## Features

- **CPU Monitoring**: Usage percentage, per-core usage, frequency, temperature
- **Memory Monitoring**: RAM usage, swap usage, detailed memory statistics
- **GPU Monitoring**: NVIDIA GPU utilization, VRAM usage, temperature, power consumption, fan speed
- **Real-time Data**: Collects metrics every second
- **Cloud Storage**: Automatic upload to S3 Express One Zone bucket
- **Systemd Integration**: Runs as a system service on Linux
- **Docker Support**: Containerized deployment with GPU support

## Quick Start

### Docker Deployment (Recommended)

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd resourcemonitor
   ```

2. **Setup configuration**
   ```bash
   # Run the interactive setup script
   sudo ./setup-config.sh
   ```

3. **Start the container**
   ```bash
   docker-compose up -d
   ```

4. **Monitor logs**
   ```bash
   docker-compose logs -f
   ```

### Native Installation (Linux/systemd)

1. **Clone and install**
   ```bash
   git clone <repository-url>
   cd resourcemonitor
   ./install.sh
   ```

2. **Configure**
   ```bash
   sudo nano /etc/resourcemonitor/config
   ```

3. **Start the service**
   ```bash
   sudo systemctl start resourcemonitor
   sudo systemctl status resourcemonitor
   ```

## Installation

### Docker Deployment

#### Prerequisites

- **Docker** and **Docker Compose**
- **sudo privileges** for configuration setup
- **NVIDIA Container Toolkit** (optional, for GPU monitoring)

#### Installation Steps

```bash
# Install Docker (Ubuntu/Debian)
sudo apt update
sudo apt install docker.io docker-compose

# Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect

# Clone repository
git clone <repository-url>
cd resourcemonitor

# Run Docker installation script
./install-docker.sh

# Start monitoring
docker-compose up -d
```

#### GPU Support (Optional)

For NVIDIA GPU monitoring, install the NVIDIA Container Toolkit:

```bash
# Install NVIDIA Container Toolkit (Ubuntu/Debian)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker

# Use GPU-enabled compose file
docker-compose -f docker-compose.gpu.yml up -d
```

### Native Installation (Linux/systemd)

#### Prerequisites

- **Python 3.8+** with `venv` module support
- **Linux system** with systemd support
- **sudo privileges**
- **AWS CLI** configured (optional)

#### System Dependencies

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install python3 python3-venv python3-pip

# RHEL/CentOS/Fedora
sudo yum install python3 python3-venv python3-pip
# or for newer versions:
sudo dnf install python3 python3-venv python3-pip
```

#### Installation Steps

```bash
# Clone repository
git clone <repository-url>
cd resourcemonitor

# Run installation script
./install.sh

# Edit configuration
sudo nano /etc/resourcemonitor/config

# Start and enable service
sudo systemctl enable resourcemonitor
sudo systemctl start resourcemonitor
```

## Configuration

### Configuration File

The application reads configuration from `/etc/resourcemonitor/config`. This file contains environment variables in `KEY=VALUE` format.

#### Using the Setup Script (Recommended)

```bash
sudo ./setup-config.sh
```

The script will interactively prompt for:
- S3 bucket name (required)
- AWS region (optional)
- AWS credentials (optional if using IAM roles)

#### Manual Configuration

```bash
sudo mkdir -p /etc/resourcemonitor
sudo tee /etc/resourcemonitor/config << EOF
# Required: S3 bucket name (must be S3 Express One Zone format)
S3_BUCKET_NAME=your-bucket-name--us-east-1a--x-s3

# Optional: AWS region
AWS_DEFAULT_REGION=us-east-1

# Optional: AWS credentials (not needed if using IAM roles)
# AWS_ACCESS_KEY_ID=your_access_key
# AWS_SECRET_ACCESS_KEY=your_secret_key
EOF

sudo chmod 644 /etc/resourcemonitor/config
```

### Configuration Parameters

| Parameter | Required | Description | Example |
|-----------|----------|-------------|---------|
| `S3_BUCKET_NAME` | Yes | S3 Express One Zone bucket name | `my-data--us-east-1a--x-s3` |
| `AWS_DEFAULT_REGION` | No | AWS region (default: us-east-1) | `us-west-2` |
| `AWS_ACCESS_KEY_ID` | No | AWS access key (if not using IAM roles) | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | No | AWS secret key (if not using IAM roles) | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |

### S3 Express One Zone Bucket

You must create an S3 Express One Zone bucket in your AWS account. The bucket name must follow the format: `bucket-name--availability-zone--x-s3`

**Examples:**
- `my-metrics--us-east-1a--x-s3`
- `monitoring-data--us-west-2b--x-s3`

### AWS Authentication

The application supports multiple authentication methods (in order of precedence):

1. **IAM Roles** (recommended for EC2 instances)
2. **Configuration file credentials**
3. **Environment variables**
4. **AWS credentials file** (`~/.aws/credentials`)
5. **Instance metadata** (for EC2 instances)

## Usage

### Docker Commands

```bash
# Start monitoring
docker-compose up -d

# View logs in real-time
docker-compose logs -f

# Check container status
docker-compose ps

# Stop monitoring
docker-compose down

# Restart container
docker-compose restart resource-monitor

# Update and restart
docker-compose build --no-cache
docker-compose up -d

# GPU monitoring
docker-compose -f docker-compose.gpu.yml up -d
```

### Native Service Commands

```bash
# Check service status
sudo systemctl status resourcemonitor

# View logs
sudo journalctl -u resourcemonitor -f

# Stop the service
sudo systemctl stop resourcemonitor

# Start the service
sudo systemctl start resourcemonitor

# Restart the service
sudo systemctl restart resourcemonitor

# Disable auto-start
sudo systemctl disable resourcemonitor
```

### Manual Execution (Development)

```bash
# Activate virtual environment
source .venv/bin/activate

# Set configuration
export S3_BUCKET_NAME=your-bucket-name--us-east-1a--x-s3

# Run the monitor
python resource_monitor.py
```

## Data Format

The monitoring data is stored in JSON format with the following structure:

```json
{
  "timestamp": "2025-08-02T12:00:00Z",
  "hostname": "monitoring-server",
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

## Monitoring and Logging

### Log Locations

- **Docker**: Container logs via `docker-compose logs`
- **Native**: 
  - Application logs: `/var/log/resourcemonitor.log`
  - System logs: `journalctl -u resourcemonitor`

### Log Levels

The application logs the following events:
- **INFO**: Successful operations, metrics collection
- **WARNING**: Recoverable errors, missing optional features
- **ERROR**: Failed operations, connection issues
- **CRITICAL**: Unrecoverable errors

## Troubleshooting

### Common Issues

#### Configuration Problems

```bash
# Check configuration file exists and is readable
ls -la /etc/resourcemonitor/config

# Verify configuration syntax
cat /etc/resourcemonitor/config

# Test S3 connectivity
aws s3 ls s3://your-bucket-name--us-east-1a--x-s3/
```

#### Docker Issues

```bash
# Check container status
docker-compose ps

# View detailed logs
docker-compose logs --details

# Test container connectivity
docker exec -it resource-monitor /bin/bash

# Rebuild container
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

#### Native Installation Issues

```bash
# Check service status
sudo systemctl status resourcemonitor

# View recent logs
sudo journalctl -u resourcemonitor --since "1 hour ago"

# Test Python dependencies
/opt/resourcemonitor/.venv/bin/python -c "import psutil, boto3; print('Dependencies OK')"

# Test GPU support (if applicable)
/opt/resourcemonitor/.venv/bin/python -c "import pynvml; print('GPU support OK')"
```

### Performance Issues

- **High CPU usage**: Reduce monitoring frequency in the code
- **High memory usage**: Check for memory leaks in logs
- **Network issues**: Verify S3 connectivity and credentials
- **GPU monitoring**: Ensure NVIDIA drivers are properly installed

### AWS Issues

```bash
# Test AWS credentials
aws sts get-caller-identity

# Test S3 access
aws s3 ls

# Check S3 bucket permissions
aws s3api get-bucket-policy --bucket your-bucket-name--us-east-1a--x-s3
```

## Security

### Best Practices

- **IAM Roles**: Use IAM roles instead of access keys when possible
- **Minimal Permissions**: Grant only necessary S3 permissions
- **Configuration Security**: Protect `/etc/resourcemonitor/config` with appropriate file permissions
- **Container Security**: Run containers with non-root user (automatically configured)

### File Permissions

```bash
# Configuration file permissions
sudo chown root:root /etc/resourcemonitor/config
sudo chmod 644 /etc/resourcemonitor/config

# Application directory permissions (native installation)
sudo chown -R resourcemonitor:resourcemonitor /opt/resourcemonitor
```

## Performance Considerations

- **S3 Express One Zone**: Provides single-digit millisecond latency for high-frequency uploads
- **Memory Efficient**: Minimal memory footprint (~50MB typical usage)
- **CPU Overhead**: Less than 1% CPU usage on modern systems
- **Network Bandwidth**: Approximately 1KB per metric upload
- **Storage**: Each JSON record is typically 1-2KB

## Cost Optimization

- **S3 Express One Zone**: Optimized for high-frequency access patterns
- **Efficient Data Format**: Compact JSON structure minimizes storage costs
- **No Data Retention**: Implement lifecycle policies if long-term storage is not needed

## Development

### Project Structure

```
resourcemonitor/
├── resource_monitor.py      # Main monitoring application
├── requirements.txt         # Python dependencies
├── Dockerfile              # Container definition
├── docker-compose.yml      # Docker Compose configuration
├── docker-compose.gpu.yml  # GPU-enabled Docker Compose
├── resourcemonitor.service # systemd service file
├── install.sh              # Native installation script
├── install-docker.sh       # Docker installation script
├── setup-config.sh         # Configuration setup script
├── test_monitor.py         # Test script
└── README.md               # This file
```

### Dependencies

- **psutil**: System metrics collection
- **boto3**: AWS S3 integration
- **nvidia-ml-py**: NVIDIA GPU monitoring (optional)
- **python-dotenv**: Configuration file loading

### Testing

```bash
# Test monitoring without S3 upload
python test_monitor.py

# Test Docker build
docker build -t resource-monitor:test .

# Test configuration setup
sudo ./setup-config.sh
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Add tests if applicable
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:

1. **Check the troubleshooting section** in this README
2. **Review the logs** for error messages
3. **Open an issue** on the GitHub repository
4. **Check existing issues** for similar problems

### Useful Commands for Support

```bash
# Collect system information
uname -a
docker --version
python3 --version

# Collect application logs
sudo journalctl -u resourcemonitor --since "1 hour ago" > resourcemonitor.log

# Test basic functionality
docker-compose ps
docker-compose logs --tail=50
```
