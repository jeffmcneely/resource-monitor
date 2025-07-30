<!-- Use this file to provide workspace-specific custom instructions to Copilot. For more details, visit https://code.visualstudio.com/docs/copilot/copilot-customization#_use-a-githubcopilotinstructionsmd-file -->

# Resource Monitor Project Instructions

This is a Python-based system resource monitoring application that:

- Monitors CPU usage, NVIDIA GPU metrics, system RAM, GPU VRAM, and CPU temperature
- Collects data every second and uploads to AWS S3 Express One Zone bucket
- Runs as a systemd service for continuous operation
- Uses CloudFormation for infrastructure deployment

## Key Technologies

- **Python 3.8+** with psutil, nvidia-ml-py, boto3, python-dotenv
- **AWS S3 Express One Zone** for high-performance data storage
- **systemd** for service management on Linux
- **CloudFormation** for infrastructure as code
- **AWS SAM** for deployment automation

## Architecture

- `resource_monitor.py`: Main monitoring application
- `resourcemonitor.service`: systemd service configuration
- `s3-express-bucket.yaml`: CloudFormation template for AWS resources
- `samconfig.toml`: SAM deployment configuration
- `install.sh`: Automated installation script

## Code Style Guidelines

- Use type hints for function parameters and return values
- Include comprehensive error handling and logging
- Follow PEP 8 style guidelines
- Use descriptive variable and function names
- Add docstrings for all classes and functions
- Handle optional dependencies gracefully (e.g., NVIDIA GPU support)

## AWS Integration

- Use boto3 for S3 operations
- Implement proper IAM role-based authentication
- Handle AWS service errors gracefully
- Use S3 Express One Zone for optimal performance
- Include CloudFormation outputs for easy integration

## Security Considerations

- Run service with minimal privileges
- Use secure systemd configuration options
- Implement proper AWS IAM policies
- Avoid hardcoding credentials in code
- Use environment variables for configuration
