#!/bin/bash

# Deployment script for JourneyGuide to AWS ECS
# Usage: ./deploy.sh [version]

set -e

# Configuration
AWS_REGION="us-west-2"
AWS_ACCOUNT_ID="347277718006"
ECR_REPOSITORY="journeyguide"
ECS_CLUSTER="sprkzdoc-cluster-dev"
ECS_SERVICE="journeyguide-service"

# Get version from argument or use 'latest'
VERSION=${1:-latest}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "========================================="
echo "Deploying JourneyGuide to AWS ECS"
echo "Version: $VERSION"
echo "Timestamp: $TIMESTAMP"
echo "========================================="

# Step 1: Build Docker image
echo ""
echo "Step 1: Building Docker image..."
docker build -t $ECR_REPOSITORY:$VERSION .
docker tag $ECR_REPOSITORY:$VERSION $ECR_REPOSITORY:$TIMESTAMP

# Step 2: Login to ECR
echo ""
echo "Step 2: Logging in to ECR..."
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Step 3: Tag and push images
echo ""
echo "Step 3: Tagging and pushing images to ECR..."
docker tag $ECR_REPOSITORY:$VERSION \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$VERSION

docker tag $ECR_REPOSITORY:$VERSION \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$TIMESTAMP

docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$VERSION
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$TIMESTAMP

# Step 4: Force new deployment
echo ""
echo "Step 4: Triggering ECS service update..."
aws ecs update-service \
  --cluster $ECS_CLUSTER \
  --service $ECS_SERVICE \
  --force-new-deployment \
  --region $AWS_REGION \
  > /dev/null

echo ""
echo "========================================="
echo "Deployment initiated successfully!"
echo "Image: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$VERSION"
echo "Timestamp tag: $TIMESTAMP"
echo ""
echo "Monitor deployment:"
echo "  aws ecs describe-services --cluster $ECS_CLUSTER --services $ECS_SERVICE --region $AWS_REGION"
echo ""
echo "View logs:"
echo "  aws logs tail /ecs/journeyguide --follow --region $AWS_REGION"
echo "========================================="
