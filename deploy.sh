#!/bin/bash

# Define variables
LAMBDA_ZIP="lambda.zip"
DOCKER_IMAGE="lambda-build"
PROJECT_DIR=$(pwd)

# Step 1: Build the Docker image
echo "Building Docker image..."
docker build -t $DOCKER_IMAGE .

# Step 2: Run the Docker container to package the Lambda function
echo "Packaging Lambda function into $LAMBDA_ZIP..."
docker run --rm -v $PROJECT_DIR:/var/task $DOCKER_IMAGE bash -c "
    zip -r $LAMBDA_ZIP . -x '*.git*' -x 'docker-compose.yml'
"

# Step 3: Apply the Terraform configuration
echo "Deploying the Lambda function using Terraform..."
cd terraform
terraform apply -auto-approve

# Print completion message
echo "Lambda function deployed successfully."
