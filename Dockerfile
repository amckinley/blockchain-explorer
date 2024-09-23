# Use the specific version of the AWS Lambda Python 3.9 base image that supports arm64
FROM amazon/aws-lambda-python:3.9.2024.05.20.23

# Set the working directory
WORKDIR /var/task

# Copy the requirements.txt to the container
COPY requirements.txt .

# Install dependencies
RUN pip3 install -r requirements.txt -t .

# Copy your application code
COPY app.py lambda_function.py ./

# Command to run your Lambda function in AWS Lambda environment
CMD ["lambda_function.handler"]
