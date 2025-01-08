provider "aws" {
  region = "ap-southeast-2"
}

data "aws_region" "current" {}

resource "random_string" "rand"{
  length = 24
  special = false
  upper = false
}
locals {
  namespace = substr(join("-",[var.namespace,random_string.rand.result]), 0, 24)
}

resource "aws_resourcegroups_group" "rg" {
  name = "${local.namespace}-group"
  resource_query {
    query = jsonencode({
      ResourceTypeFilters = ["AWS::AllSupported"],  # 支持所有资源类型
      TagFilters = [
        {
          Key    = "ResourceGroup",              # 标签键
          Values = [local.namespace]              # 标签值
        },{
          Key = "environment"
          Values = [var.environment]
        }
      ]
    })
    type = "TAG_FILTERS_1_0"
  }

  tags = {
    ManagedBy     = "Terraform"
    ResourceGroup = local.namespace
    environment = var.environment

  }
}

resource "aws_kms_key" "kms_key" {
  description = "KMS key"
  key_usage               = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation     = false
  tags = {
   ResourceGroup = local.namespace
   ManagedBy = "Terraform"
   environment = var.environment
  }
}
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${local.namespace}-state-bucket"
  //acl    = "private"
  force_destroy  = var.force_destroy_state

  tags = {
    ResourceGroup = local.namespace
    ManagedBy = "Terraform"
    environment = var.environment
  }
  //versioning {
    //enabled = true
  //}
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.kms_key.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}
resource "aws_s3_bucket_versioning" "s3_bucket_versioning" {
  bucket = aws_s3_bucket.s3_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block" {
  bucket = aws_s3_bucket.s3_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_dynamodb_table" "dynamodb_table" {
  name = "${local.namespace}-state-lock"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
  tags = {
    ResourceGroup = local.namespace
    ManagedBy = "Terraform"
    environment = var.environment
  }
}
