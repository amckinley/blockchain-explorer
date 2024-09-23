# Use the official AWS Lambda Python 3.9 base image
FROM amazon/aws-lambda-python:3.9

# Set the working directory
WORKDIR /var/task

# Copy the requirements.txt to the container
COPY requirements.txt .

# Install dependencies
RUN pip install -r requirements.txt -t .

# Copy your application code
COPY app.py lambda_function.py ./

# Command to run your Lambda function in AWS Lambda environment
CMD ["lambda_function.handler"]
