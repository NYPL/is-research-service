provider "aws" {
  region     = "us-east-1"
}

variable "environment" {
  type = string
  default = "qa"
  description = "The name of the environnment (qa, production). This controls the name of lambda and the env vars loaded."

  validation {
    condition     = contains(["qa", "production"], var.environment)
    error_message = "The environment must be 'qa' or 'production'."
  }
}

variable "env_vars" {
  type = map
  default = {}
  description = "Environment variables accessible to the lambda."
}

# Upload the zipped app to S3:
resource "aws_s3_object" "uploaded_zip" {
  bucket = "nypl-github-actions-builds-${var.environment}"
  key    = "is-research-service-${var.environment}-dist.zip"
  acl    = "private"
  source = "../../build/lambda-deployment.zip"
  etag = filemd5("../../build/lambda-deployment.zip")
}

# Create the lambda:
resource "aws_lambda_function" "lambda_instance" {
  description   = "A small service for determining if an item or bib is research"
  function_name = "IsResearchService-${var.environment}"
  handler       = "app.handle_event"
  memory_size   = 128
  role          = "arn:aws:iam::946183545209:role/lambda-full-access"
  runtime       = "ruby3.3"
  timeout       = 30

  # Location of the zipped code in S3:
  s3_bucket     = aws_s3_object.uploaded_zip.bucket
  s3_key        = aws_s3_object.uploaded_zip.key

  # Trigger pulling code from S3 when the zip has changed:
  source_code_hash = filebase64sha256("../../build/lambda-deployment.zip")

  tags = {
    Environment = var.environment
    Project = "LSP"
  }

  environment {
    variables = merge(
      {
        ENVIRONMENT = var.environment
      },
      var.env_vars
    )
  }
}
