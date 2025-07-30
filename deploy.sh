#!/bin/bash

# Quick deployment script for AWS resources
# This script deploys the CloudFormation stack using AWS SAM

set -e

echo "Resource Monitor - AWS Deployment Script"
echo "========================================"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    exit 1
fi

# Check if SAM CLI is installed
if ! command -v sam &> /dev/null; then
    echo "SAM CLI not found. Installing..."
    pip install aws-sam-cli
fi

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "AWS credentials verified."

# Get user input for bucket name and region
read -p "Enter bucket name prefix (default: resource-monitor-data): " BUCKET_NAME
BUCKET_NAME=${BUCKET_NAME:-resource-monitor-data}

read -p "Enter AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "Enter availability zone (default: ${AWS_REGION}a): " AZ
AZ=${AZ:-${AWS_REGION}a}

echo ""
echo "Deployment Configuration:"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $AWS_REGION"
echo "Availability Zone: $AZ"
echo ""

read -p "Continue with deployment? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Update samconfig.toml with user values
cat > samconfig.toml << EOF
version = 0.1
[default]
[default.global.parameters]
stack_name = "resource-monitor-s3"
region = "$AWS_REGION"
confirm_changeset = true
capabilities = "CAPABILITY_NAMED_IAM"
parameter_overrides = [
    "BucketName=$BUCKET_NAME",
    "AvailabilityZone=$AZ"
]

[default.build.parameters]
cached = true
parallel = true

[default.deploy.parameters]
capabilities = "CAPABILITY_NAMED_IAM"
confirm_changeset = true
resolve_s3 = true
EOF

echo "Updated samconfig.toml with your settings."

# Deploy using SAM
echo "Deploying CloudFormation stack..."
sam deploy --config-file samconfig.toml

# Get stack outputs
echo ""
echo "Deployment completed! Retrieving stack outputs..."
STACK_NAME="resource-monitor-s3"
BUCKET_NAME_OUTPUT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' --output text --region $AWS_REGION)
ROLE_ARN=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[?OutputKey==`IAMRoleArn`].OutputValue' --output text --region $AWS_REGION)

echo ""
echo "=== DEPLOYMENT SUCCESSFUL ==="
echo "S3 Bucket Name: $BUCKET_NAME_OUTPUT"
echo "IAM Role ARN: $ROLE_ARN"
echo ""
echo "Next steps:"
echo "1. Update your .env file with the bucket name:"
echo "   S3_BUCKET_NAME=$BUCKET_NAME_OUTPUT"
echo "2. For EC2 deployment, attach the IAM role to your instance"
echo "3. Run the installation script: ./install.sh"
