provider "aws" {
  region = "ap-southeast-2"
  # token      = "your_session_token" # 如果您使用临时凭证
    
}

resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
}
resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "ec2" {
  name      = "EC2-Management"
  parent_id = aws_organizations_organizational_unit.production.id
}

resource "aws_organizations_organizational_unit" "db" {
  name      = "DB-Management"
  parent_id = aws_organizations_organizational_unit.production.id
}
resource "aws_organizations_organizational_unit" "testing" {
  name      = "Testing"
  parent_id = aws_organizations_organization.org.roots[0].id
}
## SCP: EC2-Management
resource "aws_organizations_policy" "ec2_scp" {
  name        = "Allow-EC2-Only"
  description = "Allows only EC2 operations"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ec2:*"
        Resource = "*"
      },
      {
        Effect   = "Deny"
        NotAction = "ec2:*"
        Resource  = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "ec2_scp_attachment" {
  policy_id = aws_organizations_policy.ec2_scp.id
  target_id = aws_organizations_organizational_unit.ec2.id
}
## EC2 RCP
resource "aws_organizations_policy" "ec2_rcp" {
  name        = "Restrict-EC2-Instance-Types"
  description = "Restricts EC2 instance types to t3.micro and t3.small"
  type        = "RESOURCE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "ec2:RunInstances"
        Condition = {
          StringNotEqualsIfExists = {
            "ec2:InstanceType" = ["t3.micro", "t3.small"]
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "ec2_rcp_attachment" {
  policy_id = aws_organizations_policy.ec2_rcp.id
  target_id = aws_organizations_organizational_unit.ec2.id
}

## SCP: DB-Management
resource "aws_organizations_policy" "db_scp" {
  name        = "Allow-DB-Only"
  description = "Allows only database operations"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "rds:*",
          "dynamodb:*",
          "elasticache:*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Deny"
        NotAction = [
          "rds:*",
          "dynamodb:*",
          "elasticache:*"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "db_scp_attachment" {
  policy_id = aws_organizations_policy.db_scp.id
  target_id = aws_organizations_organizational_unit.db.id
}
### RCP
resource "aws_organizations_policy" "db_rcp" {
  name        = "Restrict-DB-Size"
  description = "Restricts RDS storage size and instance type"
  type        = "RESOURCE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "rds:CreateDBInstance"
        Condition = {
          NumericGreaterThanIfExists = {
            "rds:AllocatedStorage" = 100
          },
          StringNotEqualsIfExists = {
            "rds:DBInstanceClass" = "db.t3.micro"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "db_rcp_attachment" {
  policy_id = aws_organizations_policy.db_rcp.id
  target_id = aws_organizations_organizational_unit.db.id
}
### SCP: Testing
resource "aws_organizations_policy" "testing_scp" {
  name        = "Testing-Region-Restriction"
  description = "Allows all operations but restricts to a specific region"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "*"
        Resource = "*"
      },
      {
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = "us-east-1"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "testing_scp_attachment" {
  policy_id = aws_organizations_policy.testing_scp.id
  target_id = aws_organizations_organizational_unit.testing.id
}
### Test RCP
resource "aws_organizations_policy" "test_db_rcp" {
  name        = "Restrict-DB-Size"
  description = "Restricts RDS storage size and instance type"
  type        = "RESOURCE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "rds:CreateDBInstance"
        Condition = {
          NumericGreaterThanIfExists = {
            "rds:AllocatedStorage" = 10
          },
          StringNotEqualsIfExists = {
            "rds:DBInstanceClass" = "db.t2.micro"
          }
        }
      }
    ]
  })
}

resource "aws_organizations_policy_attachment" "test_db_rcp_attachment" {
  policy_id = aws_organizations_policy.test_db_rcp.id
  target_id = aws_organizations_organizational_unit.testing.id
}