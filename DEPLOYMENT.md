# Deployment Guide - JourneyGuide to AWS ECS

This guide covers deploying the JourneyGuide React application to AWS ECS (Fargate) with ALB routing.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Docker installed locally
- AWS account with necessary permissions
- Existing ALB set up in your AWS account
- ECR repository created

## Step 1: Create ECR Repository

```bash
aws ecr create-repository \
  --repository-name journeyguide \
  --region YOUR_REGION
```

## Step 2: Build and Push Docker Image

```bash
# Login to ECR
aws ecr get-login-password --region YOUR_REGION | docker login --username AWS --password-stdin YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com

# Build the Docker image
docker build -t journeyguide .

# Tag the image
docker tag journeyguide:latest YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/journeyguide:latest

# Push to ECR
docker push YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/journeyguide:latest
```

## Step 3: Create CloudWatch Log Group

```bash
aws logs create-log-group \
  --log-group-name /ecs/journeyguide \
  --region YOUR_REGION
```

## Step 4: Create ECS Target Group

```bash
aws elbv2 create-target-group \
  --name journeyguide \
  --protocol HTTP \
  --port 80 \
  --vpc-id YOUR_VPC_ID \
  --target-type ip \
  --health-check-enabled \
  --health-check-path /health \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3 \
  --region YOUR_REGION
```

## Step 5: Update Task Definition

Edit `aws/task-definition.json` and replace the following placeholders:
- `YOUR_ACCOUNT_ID` - Your AWS account ID
- `YOUR_REGION` - Your AWS region (e.g., us-east-1)

Then register the task definition:

```bash
aws ecs register-task-definition \
  --cli-input-json file://aws/task-definition.json \
  --region YOUR_REGION
```

## Step 6: Update Service Definition

Edit `aws/service-definition.json` and replace:
- `YOUR_CLUSTER_NAME` - Your ECS cluster name
- `YOUR_SUBNET_1`, `YOUR_SUBNET_2` - Private subnet IDs
- `YOUR_SECURITY_GROUP` - Security group that allows traffic from ALB
- `YOUR_REGION` - Your AWS region
- `YOUR_ACCOUNT_ID` - Your AWS account ID
- `YOUR_TG_ID` - Target group ID from Step 4

## Step 7: Create ECS Service

```bash
aws ecs create-service \
  --cli-input-json file://aws/service-definition.json \
  --region YOUR_REGION
```

## Step 8: Add ALB Listener Rule

Update `aws/alb-listener-rule.json` with:
- `YOUR_REGION` - Your AWS region
- `YOUR_ACCOUNT_ID` - Your AWS account ID
- `YOUR_TG_ID` - Target group ARN from Step 4

Create the listener rule on your existing HTTPS listener:

```bash
aws elbv2 create-rule \
  --listener-arn arn:aws:elasticloadbalancing:YOUR_REGION:YOUR_ACCOUNT_ID:listener/app/YOUR_ALB_NAME/YOUR_ALB_ID/YOUR_LISTENER_ID \
  --cli-input-json file://aws/alb-listener-rule.json \
  --region YOUR_REGION
```

## Step 9: Configure DNS

Add a CNAME record in your DNS provider:
- **Name**: `journey.dev.sprkzdoc.com`
- **Type**: CNAME or A (alias)
- **Value**: Your ALB DNS name

## Security Group Configuration

Ensure your ECS tasks security group allows:
- **Inbound**: Port 80 from ALB security group
- **Outbound**: Port 443 to 0.0.0.0/0 (for API calls to sourdough.ui.dev.sprkzdoc.com and viewer.dev.sprkzdoc.com)

Ensure your ALB security group allows:
- **Inbound**: Port 443 from 0.0.0.0/0
- **Outbound**: Port 80 to ECS tasks security group

## Deployment Updates

To deploy a new version:

```bash
# Build and push new image with version tag
docker build -t journeyguide:v1.0.1 .
docker tag journeyguide:v1.0.1 YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/journeyguide:v1.0.1
docker tag journeyguide:v1.0.1 YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/journeyguide:latest
docker push YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/journeyguide:v1.0.1
docker push YOUR_ACCOUNT_ID.dkr.ecr.YOUR_REGION.amazonaws.com/journeyguide:latest

# Force new deployment
aws ecs update-service \
  --cluster YOUR_CLUSTER_NAME \
  --service journeyguide \
  --force-new-deployment \
  --region YOUR_REGION
```

## Monitoring

View logs:
```bash
aws logs tail /ecs/journeyguide --follow --region YOUR_REGION
```

Check service status:
```bash
aws ecs describe-services \
  --cluster YOUR_CLUSTER_NAME \
  --services journeyguide \
  --region YOUR_REGION
```

## Troubleshooting

1. **Tasks failing health checks**: Check `/health` endpoint is returning 200
2. **Tasks not starting**: Check CloudWatch logs for errors
3. **ALB not routing traffic**: Verify DNS, listener rule priority, and target group health
4. **Cannot pull image**: Verify ECR permissions and image exists

## URLs

- **Application**: https://journey.dev.sprkzdoc.com/
- **Example journey paths**:
  - https://journey.dev.sprkzdoc.com/journey1
  - https://journey.dev.sprkzdoc.com/path/to/journey2

All paths will be handled by the React app, which extracts the last segment to fetch journey data.
