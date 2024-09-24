# Variables
REGION=us-west-2
AWS_ACCOUNT_ID=867018086253

DOCKER_IMAGE_NAME=flask-lambda
DOCKER_IMAGE_TAG=latest

ECR_REPO_NAME=flask-lambda-repo
ECR_REPO_URI=$(AWS_ACCOUNT_ID).dkr.ecr.$(REGION).amazonaws.com/$(ECR_REPO_NAME)
LAMBDA_FUNCTION_NAME=flask_lambda_function

# Default target (for development)
dev:
	@echo "Starting Flask app locally for development..."
	FLASK_ENV=development flask run --host=0.0.0.0 --port=5005

# Docker target to build the Docker image
docker:
	@echo "Building Docker image..."
	docker build -t $(DOCKER_IMAGE_NAME) .

# Deploy target: depends on "docker", pushes to ECR and updates the Lambda function
deploy: docker
	@echo "Tagging Docker image..."
	docker tag $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) $(ECR_REPO_URI):$(DOCKER_IMAGE_TAG)

	@echo "Pushing Docker image to ECR..."
	docker push $(ECR_REPO_URI):$(DOCKER_IMAGE_TAG)

	@echo "Triggering Lambda deployment..."
	aws lambda update-function-code \
	  --function-name $(LAMBDA_FUNCTION_NAME) \
	  --image-uri $(ECR_REPO_URI):$(DOCKER_IMAGE_TAG) \
	  --region $(REGION)

	@echo "Lambda function deployed successfully."

# Clean target: Removes Docker images (optional)
clean:
	@echo "Cleaning up Docker images..."
	docker rmi $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG) || true
	docker rmi $(ECR_REPO_URI):$(DOCKER_IMAGE_TAG) || true
