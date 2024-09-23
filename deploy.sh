#!/bin/bash

# Define variables
LAMBDA_ZIP="lambda.zip"
PROJECT_DIR=$(pwd)

# Step 1: Install dependencies
echo "Installing dependencies..."
pip install -r requirements.txt -t package

# Step 2: Package the Lambda function
echo "Packaging Lambda function..."
cd package
zip -r ../$LAMBDA_ZIP .
cd ..

# Add application files to the Lambda package
zip -g $LAMBDA_ZIP app.py lambda_function.py

# Step 3: Apply the Terraform changes
echo "Running Terraform apply..."
cd terraform
terraform apply -auto-approve

# Print completion message
echo "Lambda function deployed and Terraform applied successfully."
