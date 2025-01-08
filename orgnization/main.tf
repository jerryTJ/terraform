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
  # password = "Jerry@204#7####" 
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
  name        = "MultiServicePolicy"
  description = "Policy granting access to EC2, VPC, S3, DynamoDB, SSM, SG, IGW, NAT Gateway, and Route Tables."
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
      "Sid": "AllowVPCAccess",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVpcs",
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:ModifyVpcAttribute",
        "ec2:DescribeSubnets",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeRouteTables",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress"
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
    },
    {
      "Sid": "AllowSSMAccess",
      "Effect": "Allow",
      "Action": [
        "ssm:*",
        "ec2messages:*",
        "ssmmessages:*"
      ],
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
resource "aws_iam_user_policy_attachment" "user_policy_attachment" {
  user       = aws_iam_user.user.name
  policy_arn = aws_iam_policy.multi_service_policy.arn
}

# 创建访问密钥
resource "aws_iam_access_key" "user_access_key" {
  user    = aws_iam_user.user.name
  depends_on = [aws_iam_user.user]
}