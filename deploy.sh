#!/bin/bash

# Define variables
REGION="us-west-2"
AWS_ACCOUNT_ID="867018086253"
ECR_REPO_NAME="flask-lambda-repo"
DOCKER_IMAGE_TAG="latest"
ECR_REPO_URI="$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME"
PROJECT_DIR=$(pwd)
LAMBDA_FUNCTION_NAME="flask_lambda_function"

# Step 1: Build the Docker image
echo "Building Docker image..."
docker build -t flask-lambda .

# Step 2: Get the current digest of the 'latest' image in ECR
LATEST_DIGEST=$(aws ecr describe-images \
    --repository-name $ECR_REPO_NAME \
    --image-ids imageTag=$DOCKER_IMAGE_TAG \
    --region $REGION \
    --query 'imageDetails[0].imageDigest' \
    --output text 2>/dev/null)

# Step 3: Tag the Docker image for ECR
echo "Tagging Docker image..."
docker tag flask-lambda:latest $ECR_REPO_URI:$DOCKER_IMAGE_TAG

# Step 4: Push the Docker image to ECR
echo "Pushing Docker image to ECR..."
docker push $ECR_REPO_URI:$DOCKER_IMAGE_TAG

# Step 5: Get the new digest of the image we just pushed
NEW_DIGEST=$(aws ecr describe-images \
    --repository-name $ECR_REPO_NAME \
    --image-ids imageTag=$DOCKER_IMAGE_TAG \
    --region $REGION \
    --query 'imageDetails[0].imageDigest' \
    --output text)

# Step 6: Compare the new digest with the previous one
if [ "$LATEST_DIGEST" == "$NEW_DIGEST" ]; then
  echo "No changes detected in the Docker image. Skipping Lambda deployment."
else
  echo "New image pushed. Deploying the Lambda function with the new image."

  # Step 7: Update the Lambda function to use the new image
  aws lambda update-function-code \
    --function-name $LAMBDA_FUNCTION_NAME \
    --image-uri $ECR_REPO_URI:$DOCKER_IMAGE_TAG \
    --region $REGION

  echo "Lambda function deployed with the new image."
fi

# Print completion message
echo "Script execution completed."





