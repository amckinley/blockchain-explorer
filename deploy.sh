#!/bin/bash

# Define variables
REGION="us-west-2"
AWS_ACCOUNT_ID="867018086253"
ECR_REPO_NAME="flask-lambda-repo"
DOCKER_IMAGE_TAG="latest"
ECR_REPO_URI="$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME"
PROJECT_DIR=$(pwd)

# Step 1: Build the Docker image
echo "Building Docker image..."
docker build -t flask-lambda .

# Step 2: Tag the Docker image for ECR
echo "Tagging Docker image..."
docker tag flask-lambda:latest $ECR_REPO_URI:$DOCKER_IMAGE_TAG

# Step 3: Authenticate Docker to AWS ECR
echo "Authenticating Docker to ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_REPO_URI

# Step 4: Push the Docker image to ECR
echo "Pushing Docker image to ECR..."
docker push $ECR_REPO_URI:$DOCKER_IMAGE_TAG

# Step 5: Apply the Terraform configuration
echo "Deploying the Lambda function using Terraform..."
cd terraform
terraform apply -auto-approve

# Print completion message
echo "Lambda function deployed successfully."
