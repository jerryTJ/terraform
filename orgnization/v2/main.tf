provider "aws" {
  region     = "ap-southeast-2"
  # token      = "your_session_token" # 如果您使用临时凭证

}

resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "existing_account" {
  email     = "yunhaozhifms@163.com"
  name      = "aws_study"
  parent_id = aws_organizations_organizational_unit.production.id
  role_name = "OrganizationAccountAccessRole"
}

resource "aws_organizations_policy" "scp" {
  name        = "AllowS3AndDynamoDBOnly-v1"
  description = "Allow only S3 and DynamoDB read/write access"
  type        = "SERVICE_CONTROL_POLICY"
  content     = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowS3ReadWrite",
      "Effect": "Allow",
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*",
        "s3:DeleteObject"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowDynamoDBReadWrite",
      "Effect": "Allow",
      "Action": [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DenyAllOtherActions",
      "Effect": "Deny",
      "NotAction": [
        "s3:Get*",
        "s3:List*",
        "s3:Put*",
        "s3:DeleteObject",
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Scan",
        "dynamodb:Query"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
resource "aws_organizations_policy_attachment" "attachment" {
  policy_id = aws_organizations_policy.scp.id
  target_id = aws_organizations_organizational_unit.production.id
}
