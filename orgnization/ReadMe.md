AWS Organizations 最佳实践， 比如管理生产和测试的账户， 生产有10个账户，5个负责管理 ec3， 5个负责管理DB， 如mysql，drymaticDB,redis, 测试20个账户，负责管理所有的测试资源，该如何划分 ou

Root OU
├── 生产 OU
│   ├── EC2 管理 OU
│   │   ├── EC2 账户 1
│   │   ├── EC2 账户 2
│   │   ├── EC2 账户 3
│   │   ├── EC2 账户 4
│   │   └── EC2 账户 5
│   ├── 数据库管理 OU
│   │   ├── MySQL 管理 OU
│   │   │   ├── MySQL 账户 1
│   │   │   ├── MySQL 账户 2
│   │   ├── DynamoDB 管理 OU
│   │   │   ├── DynamoDB 账户 1
│   │   │   ├── DynamoDB 账户 2
│   │   └── Redis 管理 OU
│   │       ├── Redis 账户 1
│   │       ├── Redis 账户 2
├── 测试 OU
    ├── 测试账户 1
    ├── 测试账户 2
    ├── ...
    └── 测试账户 20

## SCP policy

### EC2

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "ec2:*",
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "NotAction": "ec2:*",
      "Resource": "*"
    }
  ]
}

### RCP

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Condition": {
        "StringNotEqualsIfExists": {
          "ec2:InstanceType": [
            "t3.micro",
            "t3.small"
          ]
        }
      }
    }
  ]
}

### DB

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "rds:*",
        "dynamodb:*",
        "elasticache:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "NotAction": [
        "rds:*",
        "dynamodb:*",
        "elasticache:*"
      ],
      "Resource": "*"
    }
  ]
}

### RCP

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "rds:CreateDBInstance",
      "Condition": {
        "NumericGreaterThanIfExists": {
          "rds:AllocatedStorage": 100
        },
        "StringNotEqualsIfExists": {
          "rds:DBInstanceClass": "db.t3.micro"
        }
      }
    }
  ]
}

### test env ou 除了u-east-1

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "*",
      "Resource": "*"
    },
    {
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": "us-east-1"
        }
      }
    }
  ]
}

### RCP

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Condition": {
        "StringNotEqualsIfExists": {
          "ec2:InstanceType": "t2.micro"
        }
      }
    },
    {
      "Effect": "Deny",
      "Action": "ec2:RunInstances",
      "Condition": {
        "NumericGreaterThanIfExists": {
          "aws:RequestTag/InstanceCount": 10
        }
      }
    }
  ]
}
6. 账户管理的最佳实践

标签（Tagging）
 • 给账户和资源添加标签（如 Environment=Production 或 Service=EC2），便于跨账户进行资源管理。

集中式监控
 • 使用 AWS CloudTrail 和 AWS Config 对所有账户进行集中式监控，确保符合合规性要求。

成本优化
 • 为测试 OU 启用成本分配报告，跟踪和控制测试资源的使用。
