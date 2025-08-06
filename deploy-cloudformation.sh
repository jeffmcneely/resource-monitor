#!/bin/bash

# CloudFormation deployment script for Resource Monitor infrastructure
# This script deploys the S3 bucket with access point and IAM resources

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/cloudformation-template.yaml"

echo "Resource Monitor - CloudFormation Deployment Script"
echo "=================================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI is not installed. Please install it first."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Check AWS credentials
echo "Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CURRENT_REGION=$(aws configure get region || echo "us-east-1")

echo "AWS credentials verified."
echo "Account ID: $ACCOUNT_ID"
echo "Current region: $CURRENT_REGION"
echo ""

# Get user input for parameters
read -p "Enter stack name (default: resource-monitor-infrastructure): " STACK_NAME
STACK_NAME=${STACK_NAME:-resource-monitor-infrastructure}

read -p "Enter bucket name prefix (default: resource-monitor-data): " BUCKET_NAME
BUCKET_NAME=${BUCKET_NAME:-resource-monitor-data}

read -p "Enter environment (dev/staging/prod, default: prod): " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-prod}

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    echo "Error: Environment must be one of: dev, staging, prod"
    exit 1
fi

read -p "Enter AWS region (default: $CURRENT_REGION): " AWS_REGION
AWS_REGION=${AWS_REGION:-$CURRENT_REGION}

echo ""
echo "Deployment Configuration:"
echo "Stack Name: $STACK_NAME"
echo "Bucket Name: $BUCKET_NAME"
echo "Environment: $ENVIRONMENT"
echo "Region: $AWS_REGION"
echo ""

read -p "Continue with deployment? (y/N): " CONFIRM
if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

# Check if stack already exists
echo "Checking if stack already exists..."
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" --region "$AWS_REGION" &> /dev/null; then
    echo "Stack '$STACK_NAME' already exists. This will update the existing stack."
    read -p "Continue with stack update? (y/N): " UPDATE_CONFIRM
    if [[ ! $UPDATE_CONFIRM =~ ^[Yy]$ ]]; then
        echo "Update cancelled."
        exit 0
    fi
    OPERATION="update"
else
    echo "Stack '$STACK_NAME' does not exist. Creating new stack."
    OPERATION="create"
fi

# Validate CloudFormation template
echo "Validating CloudFormation template..."
if ! aws cloudformation validate-template --template-body file://"$TEMPLATE_FILE" --region "$AWS_REGION" &> /dev/null; then
    echo "Error: CloudFormation template validation failed."
    aws cloudformation validate-template --template-body file://"$TEMPLATE_FILE" --region "$AWS_REGION"
    exit 1
fi
echo "Template validation successful."

# Deploy the stack
echo ""
echo "Deploying CloudFormation stack..."
if [[ "$OPERATION" == "create" ]]; then
    aws cloudformation create-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://"$TEMPLATE_FILE" \
        --parameters \
            ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
            ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$AWS_REGION" \
        --tags \
            Key=Project,Value=ResourceMonitor \
            Key=Environment,Value="$ENVIRONMENT" \
            Key=ManagedBy,Value=CloudFormation
else
    aws cloudformation update-stack \
        --stack-name "$STACK_NAME" \
        --template-body file://"$TEMPLATE_FILE" \
        --parameters \
            ParameterKey=BucketName,ParameterValue="$BUCKET_NAME" \
            ParameterKey=Environment,ParameterValue="$ENVIRONMENT" \
        --capabilities CAPABILITY_NAMED_IAM \
        --region "$AWS_REGION" \
        --tags \
            Key=Project,Value=ResourceMonitor \
            Key=Environment,Value="$ENVIRONMENT" \
            Key=ManagedBy,Value=CloudFormation
fi

echo "Stack deployment initiated. Waiting for completion..."

# Wait for stack operation to complete
aws cloudformation wait stack-${OPERATION}-complete \
    --stack-name "$STACK_NAME" \
    --region "$AWS_REGION"

if [[ $? -eq 0 ]]; then
    echo ""
    echo "=== DEPLOYMENT SUCCESSFUL ==="
    
    # Get stack outputs
    echo "Retrieving stack outputs..."
    OUTPUTS=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs' \
        --output table)
    
    echo ""
    echo "Stack Outputs:"
    echo "$OUTPUTS"
    
    # Get specific values for easy copying
    BUCKET_NAME_OUTPUT=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
        --output text)
    
    ROLE_ARN=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`IAMRoleArn`].OutputValue' \
        --output text)
    
    ACCESS_KEY_ID=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`AccessKeyId`].OutputValue' \
        --output text)
    
    ACCESS_POINT_ARN=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`AccessPointArn`].OutputValue' \
        --output text)
    
    DASHBOARD_URL=$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --region "$AWS_REGION" \
        --query 'Stacks[0].Outputs[?OutputKey==`DashboardURL`].OutputValue' \
        --output text)
    
    echo ""
    echo "=== QUICK REFERENCE ==="
    echo "S3 Bucket: $BUCKET_NAME_OUTPUT"
    echo "IAM Role ARN: $ROLE_ARN"
    echo "Access Key ID: $ACCESS_KEY_ID"
    echo "Access Point ARN: $ACCESS_POINT_ARN"
    echo "CloudWatch Dashboard: $DASHBOARD_URL"
    echo ""
    echo "=== CONFIGURATION FOR RESOURCE MONITOR ==="
    echo "Add these to your /etc/resourcemonitor/config file:"
    echo ""
    echo "S3_BUCKET_NAME=$BUCKET_NAME_OUTPUT"
    echo "AWS_DEFAULT_REGION=$AWS_REGION"
    echo ""
    echo "For EC2 deployment:"
    echo "  - Attach IAM role: $ROLE_ARN"
    echo ""
    echo "For external deployment:"
    echo "  - Use Access Key ID: $ACCESS_KEY_ID"
    echo "  - Get Secret Key from CloudFormation outputs (marked as NoEcho)"
    echo ""
    echo "=== READ-ONLY ACCESS ==="
    echo "Access Point ARN for read-only JSON access: $ACCESS_POINT_ARN"
    echo "Add users to the 'ResourceMonitor-$ENVIRONMENT-ReadOnly' IAM group for read-only access"
    echo ""
    echo "=== MONITORING ==="
    echo "CloudWatch Dashboard: $DASHBOARD_URL"
    echo ""
    echo "Deployment completed successfully!"
    
else
    echo ""
    echo "=== DEPLOYMENT FAILED ==="
    echo "Check the CloudFormation console for error details:"
    echo "https://$AWS_REGION.console.aws.amazon.com/cloudformation/home?region=$AWS_REGION#/stacks"
    exit 1
fi
