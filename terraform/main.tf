provider "aws" {
  region = var.region
}

# Get the current AWS account ID
data "aws_caller_identity" "current" {}


resource "aws_iam_role" "lambda_role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  # Attach the necessary permissions for ECR and Lambda execution
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
}

# Add a custom policy for ECR access
resource "aws_iam_policy" "lambda_ecr_policy" {
  name        = "lambda-ecr-policy"
  description = "Policy for Lambda to access ECR"
  policy      = jsonencode({
    Version: "2012-10-17",
    Statement: [
      {
        Effect: "Allow",
        Action: [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource: "arn:aws:ecr:${var.region}:${data.aws_caller_identity.current.account_id}:repository/${aws_ecr_repository.flask_lambda_repo.name}"
      },
      {
        Effect: "Allow",
        Action: "ecr:GetAuthorizationToken",
        Resource: "*"
      }
    ]
  })
}

# Attach the custom ECR policy to the Lambda IAM role
resource "aws_iam_role_policy_attachment" "lambda_ecr_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_ecr_policy.arn
}


# Lambda function
resource "aws_lambda_function" "flask_lambda" {
  function_name = "flask_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"  # Specify that this Lambda function uses a container image
  image_uri     = "867018086253.dkr.ecr.us-west-2.amazonaws.com/flask-lambda-repo:latest"
  architectures = ["arm64"]  # Switch to Graviton

  environment {
    variables = {
      ENV     = "prod"
      API_KEY = var.api_key
    }
  }

  timeout = 30
}


resource "aws_api_gateway_rest_api" "api" {
  name        = "flask-api"
  description = "API Gateway for Flask app"
}

# Root method for API Gateway
resource "aws_api_gateway_method" "root_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_rest_api.api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# Root integration with Lambda function
resource "aws_api_gateway_integration" "root_integration" {
  rest_api_id            = aws_api_gateway_rest_api.api.id
  resource_id            = aws_api_gateway_rest_api.api.root_resource_id
  http_method            = aws_api_gateway_method.root_method.http_method
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.flask_lambda.invoke_arn
}

# Proxy resource for all other routes
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

# Proxy method
resource "aws_api_gateway_method" "proxy_method" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# Proxy integration with Lambda
resource "aws_api_gateway_integration" "proxy_integration" {
  rest_api_id            = aws_api_gateway_rest_api.api.id
  resource_id            = aws_api_gateway_resource.proxy.id
  http_method            = aws_api_gateway_method.proxy_method.http_method
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.flask_lambda.arn}/invocations"
}

# Deploy API Gateway
resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_method.root_method,
    aws_api_gateway_integration.root_integration,
    aws_api_gateway_method.proxy_method,
    aws_api_gateway_integration.proxy_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = "prod"
}

# Lambda permission to allow API Gateway to invoke it
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.flask_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.api.id}/*"
}

resource "aws_ecr_repository" "flask_lambda_repo" {
  name = "flask-lambda-repo"

  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "flask_lambda_policy" {
  repository = aws_ecr_repository.flask_lambda_repo.name

  policy = <<POLICY
{
  "rules": [
    {
      "rulePriority": 1,
      "description": "Delete untagged images after 1 day",
      "selection": {
        "tagStatus": "untagged",
        "countType": "sinceImagePushed",
        "countUnit": "days",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    }
  ]
}
POLICY
}


# Output the API URL
output "api_url" {
  value = aws_api_gateway_deployment.deployment.invoke_url
}
