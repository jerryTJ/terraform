# 在 ~/.aws/config 文件中为指定的角色添加配置

[profile terraform-role]
role_arn = arn:aws:iam::*******:role/s3backend-gkv6d0r7acqsa7-tf-assume-role
source_profile = default
region = ap-southeast-2

export AWS_PROFILE="terraform-role"
terraform init
terraform apply

1、使用terraform 在aws上创建一下服务
 1）创建一个vpc 网络模块， CIDR 块 10.0.0.0/16，公共子网: 10.0.1.0/24，关联 Internet Gateway，并启用DNS，私有子网: 10.0.2.0/24，关联 NAT Gateway，公共子网: 默认路由指向 Internet Gateway，私有子网: 默认路由指向 NAT Gateway,添加Security group，只允许 22和8080端口访问，添加 vpc enpoint，可以访问 aws ec2，ssm，ec2messages, ssmmessages,s3和database等服务
 创建一个免费的ec2，type ，可以通过SSM访问该ec2实例
2） 创建一个Ec2模块，创建一个免费的ec2实例，os 为ubuntu，安装mysql 客户端，并关联一个launch template，该实例存放私有子网中，
3） 创建一个DB模块，engine =mysql,  类型为 db.t2.micro 最小配置实例，该实例放在私有子网中，
2）创建一个autoscaling 模块，添加 alb和auto scaling服务，最大和最小实例都是1
