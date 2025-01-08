provider "aws" {
  region     = "ap-southeast-2"
  # token      = "your_session_token" # 如果您使用临时凭证
}

# 创建 IAM 用户
resource "aws_iam_user" "user" {
  name = "terraform-state"
}

resource "aws_iam_user_login_profile" "login_profile" {
  user    = aws_iam_user.user.name 
  password_reset_required = true
}

# 或 IAM 角色
resource "aws_iam_role" "admin_role" {
  name = aws_iam_user.user.name
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
# IAM 策略
resource "aws_iam_policy" "multi_service_policy" {
  name        = "ec2-s3-policy"
  description = "Policy granting access to EC2 s3."
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEC2Access",
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowS3Access",
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    },
    {
      "Sid": "AllowDynamoDBAccess",
      "Effect": "Allow",
      "Action": "dynamodb:*",
      "Resource": "*"
    }
  ]
}
POLICY
}

# 将托管角色附加到用户
resource "aws_iam_user_policy_attachment" "attach_change_password" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

# KMS
resource "aws_iam_user_policy_attachment" "attach_kms_policy" {
  user       = aws_iam_user.user.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ROSAKMSProviderPolicy"
}

resource "aws_iam_user_policy_attachment" "user_policy_attachment" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.multi_service_policy.arn
}

# 创建访问密钥
resource "aws_iam_access_key" "user_access_key" {
  user    = aws_iam_user.user.name
  depends_on = [aws_iam_user.user]
}

