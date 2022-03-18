data "aws_caller_identity" "current" {}

data "aws_region" "current" {}


resource "aws_iam_role" "lambda-role" {
  name = join("", [var.DeploymentName, "-lambda-role"])
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
  inline_policy {
    name = join("", [var.DeploymentName, "-lambda-policy"])

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : ["s3:PutObject", "s3:PutObjectAcl"],
          "Resource" : join("", ["arn:aws:s3:::", var.S3BucketName, "/*"])
        },
        {
          "Effect" : "Allow",
          "Action" : "logs:CreateLogGroup",
          "Resource" : join("", ["arn:aws:logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":*"])
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : [
            join("", ["arn:aws:logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":", "log-group:/aws/lambda/", var.DeploymentName, "-lambda-sub-filter:*"])
          ]
        }
      ]
    })
  }
}


resource "aws_lambda_function" "lambda-sub-filter" {
  function_name    = join("", [var.DeploymentName, "-lambda-sub-filter"])
  role             = aws_iam_role.lambda-role.arn
  handler          = "lambda_function.lambda_handler"
  filename         = "./zip/lambda.zip"
  source_code_hash = filebase64sha256("./zip/lambda.zip")
  runtime          = "python3.8"
  memory_size      = 128
  timeout          = 10
  environment {
    variables = {
      S3_BUCKET_NAME = var.S3BucketName
      PROJECT_NAME   = var.ProjectName
    }
  }
}


resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "flymybirdfromloggroups"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda-sub-filter.function_name
  principal     = join("", ["logs.", data.aws_region.current.name, ".amazonaws.com"])
  source_arn    = join("", ["arn:aws:logs:", data.aws_region.current.name, ":", data.aws_caller_identity.current.account_id, ":log-group:*"])
}


resource "aws_cloudwatch_log_group" "loggroups" {
  depends_on        = [aws_lambda_permission.allow_cloudwatch]
  count             = var.LogGroupCount
  name              = join("", [var.LogGroupPrefix, count.index])
  retention_in_days = var.LogRetention
}


resource "aws_cloudwatch_log_subscription_filter" "sub-filter" {
  depends_on      = [aws_cloudwatch_log_group.loggroups]
  count           = var.LogGroupCount
  name            = join("", [var.DeploymentName,"-",var.LogGroupPrefix, count.index])
  log_group_name  = join("", [var.LogGroupPrefix, count.index])
  filter_pattern  = ""
  destination_arn = aws_lambda_function.lambda-sub-filter.arn
}
