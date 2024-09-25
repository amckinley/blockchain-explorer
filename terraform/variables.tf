variable "region" {
  description = "The AWS region to deploy the Lambda function"
  type        = string
  default     = "us-west-2"  # You can change this to your preferred region
}

variable "api_key" {
  description = "The Infura API key for Ethereum"
  type        = string
}
