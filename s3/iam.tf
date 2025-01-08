data "aws_caller_identity" "current" {}

locals {
  principal_arns = var.principal_arns !=null ? var.principal_arns : [data.aws_caller_identity.current.arn]
}
resource "aws_iam_role" "iam_role" {
  name = "${local.namespace}-tf-assume-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          AWS = local.principal_arns
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    ResourceGroup = local.namespace
    ManagedBy = "Terraform"
    environment = var.environment
  }
}
data "aws_iam_policy_document" "iam_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${local.namespace}-state-bucket/*"
    ]
  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.namespace}-state-bucket"
    ]
  }
  statement {
    actions = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      aws_kms_key.kms_key.arn
    ]
  }
  statement {
    actions =[
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:DeleteItem",
    ]
    resources = [
      aws_dynamodb_table.dynamodb_table.arn
    ]
  }
}
resource "aws_iam_policy" "iam_policy" {
  name = "${local.namespace}-tf-policy"
  policy = data.aws_iam_policy_document.iam_policy.json
  tags = {
    ResourceGroup = local.namespace
    ManagedBy = "Terraform"
    environment = var.environment
  }
}
resource "aws_iam_role_policy_attachment" "role_policy_attachment" {
  role = aws_iam_role.iam_role.name
  policy_arn = aws_iam_policy.iam_policy.arn
}