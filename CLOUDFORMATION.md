# CloudFormation Infrastructure

This directory contains AWS CloudFormation templates and deployment scripts for setting up the complete Resource Monitor infrastructure.

## Files

- `cloudformation-template.yaml` - Main CloudFormation template
- `deploy-cloudformation.sh` - Automated deployment script

## Architecture

The CloudFormation template creates the following AWS resources:

### Core Resources
- **S3 Bucket** - Primary storage for metrics data with versioning and encryption
- **S3 Access Point** - Controlled access point with read-only JSON file access policy
- **CloudWatch Log Group** - For S3 event logging and monitoring

### IAM Resources
- **IAM Role** - For EC2 instances running the Resource Monitor
- **Instance Profile** - Attached to EC2 instances for automatic credential management
- **IAM User** - For external/development access with programmatic credentials
- **IAM Group** - Read-only group for dashboard/reporting access

### Monitoring
- **CloudWatch Dashboard** - Pre-configured dashboard for S3 metrics and upload activity
- **Lifecycle Policies** - Automatic data management and cost optimization

## S3 Access Point Policy

The access point implements read-only access to `*.json` files with the following policy:

```yaml
Policy:
  Version: '2012-10-17'
  Statement:
    - Sid: AllowReadOnlyJSONAccess
      Effect: Allow
      Principal:
        AWS: !Sub 'arn:aws:iam::${AWS::AccountId}:root'
      Action:
        - 's3:GetObject'
        - 's3:ListBucket'
      Resource:
        - '${ResourceMonitorBucket}/*'
        - '${ResourceMonitorBucket}'
      Condition:
        StringLike:
          's3:prefix': '*.json'
    - Sid: DenyNonJSONAccess
      Effect: Deny
      Principal: '*'
      Action: 's3:GetObject'
      Resource: '${ResourceMonitorBucket}/*'
      Condition:
        StringNotLike:
          's3:ExistingObjectTag/ContentType': 'application/json'
```

## Quick Deployment

### Prerequisites
- AWS CLI installed and configured
- Appropriate AWS permissions for CloudFormation, S3, and IAM

### Deploy Infrastructure

```bash
# Make script executable (if not already)
chmod +x deploy-cloudformation.sh

# Run deployment script
./deploy-cloudformation.sh
```

The script will prompt for:
- Stack name (default: `resource-monitor-infrastructure`)
- Bucket name prefix (default: `resource-monitor-data`)
- Environment (`dev`/`staging`/`prod`)
- AWS region

### Manual Deployment

```bash
# Validate template
aws cloudformation validate-template \
  --template-body file://cloudformation-template.yaml

# Deploy stack
aws cloudformation create-stack \
  --stack-name resource-monitor-infrastructure \
  --template-body file://cloudformation-template.yaml \
  --parameters \
    ParameterKey=BucketName,ParameterValue=resource-monitor-data \
    ParameterKey=Environment,ParameterValue=prod \
  --capabilities CAPABILITY_NAMED_IAM \
  --region us-east-1
```

## Output Values

The template provides the following outputs:

| Output | Description | Usage |
|--------|-------------|-------|
| `BucketName` | S3 bucket name | Set as `S3_BUCKET_NAME` in Resource Monitor config |
| `AccessPointArn` | Read-only access point ARN | For dashboard/reporting applications |
| `IAMRoleArn` | EC2 instance role ARN | Attach to EC2 instances |
| `InstanceProfileArn` | Instance profile ARN | Used automatically with IAM role |
| `AccessKeyId` | Programmatic access key | For external deployments |
| `SecretAccessKey` | Secret access key | Store securely, use with AccessKeyId |
| `ReadOnlyGroupName` | IAM group for read access | Add users for dashboard access |
| `DashboardURL` | CloudWatch dashboard URL | Monitor S3 activity and metrics |

## Configuration Integration

After deployment, update your Resource Monitor configuration:

### For EC2 Instances
```bash
# /etc/resourcemonitor/config
S3_BUCKET_NAME=resource-monitor-data-prod-123456789012
AWS_DEFAULT_REGION=us-east-1

# Attach the IAM role to your EC2 instance
# No access keys needed - uses instance metadata
```

### For External Deployment
```bash
# /etc/resourcemonitor/config
S3_BUCKET_NAME=resource-monitor-data-prod-123456789012
AWS_DEFAULT_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## Read-Only Access Setup

### For Dashboard Applications

1. **Add users to the read-only group:**
   ```bash
   aws iam add-user-to-group \
     --group-name ResourceMonitor-prod-ReadOnly \
     --user-name dashboard-user
   ```

2. **Access via Access Point:**
   ```python
   import boto3
   
   # Use the access point ARN
   s3_client = boto3.client('s3')
   response = s3_client.get_object(
       Bucket='arn:aws:s3:us-east-1:123456789012:accesspoint/resource-monitor-data-prod-readonly-ap',
       Key='server01.json'
   )
   ```

### Access Point Benefits

- **Restricted Access** - Only allows reading JSON files
- **Audit Trail** - All access logged through CloudTrail
- **Policy Isolation** - Access policies separate from bucket policies
- **Multi-Account** - Can be shared across AWS accounts securely

## Cost Optimization Features

### Lifecycle Policies
- **History data** expires after 90 days
- **Current metrics** transition to Standard-IA after 30 days
- **Versioned objects** cleaned up automatically

### Monitoring
- CloudWatch dashboard tracks usage and costs
- S3 metrics help optimize storage classes
- Log analysis identifies usage patterns

## Security Features

### Encryption
- **Server-side encryption** with AES-256
- **Encryption in transit** via HTTPS
- **Access logging** for audit trails

### Access Control
- **IAM roles** for EC2 instances (no long-term keys)
- **Principle of least privilege** for all policies
- **Read-only access point** for dashboard applications
- **Public access blocking** enabled on bucket

### Monitoring
- **CloudTrail integration** for API logging
- **CloudWatch events** for S3 operations
- **Access point logging** for compliance

## Troubleshooting

### Common Issues

1. **Insufficient Permissions**
   ```bash
   # Check your AWS permissions
   aws iam get-user
   aws iam list-attached-user-policies --user-name $(aws sts get-caller-identity --query User.UserName --output text)
   ```

2. **Stack Creation Failed**
   ```bash
   # Check CloudFormation events
   aws cloudformation describe-stack-events --stack-name resource-monitor-infrastructure
   ```

3. **Access Point Access Denied**
   ```bash
   # Verify access point policy
   aws s3control get-access-point-policy --account-id $(aws sts get-caller-identity --query Account --output text) --name resource-monitor-data-prod-readonly-ap
   ```

### Cleanup

To remove all resources:

```bash
# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name resource-monitor-infrastructure

# Wait for deletion to complete
aws cloudformation wait stack-delete-complete --stack-name resource-monitor-infrastructure
```

**Note:** The S3 bucket must be empty before the stack can be deleted. Remove all objects first if needed.
