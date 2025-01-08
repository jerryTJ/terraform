provider "aws" {
  region     = "ap-southeast-2"

}

resource "aws_iam_role" "sts_role" {
  name = "sts_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { AWS = "arn:aws:iam::007638882300:user/terraform-state" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "sts_policy" {
  name   = "sts-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:GetObject", "s3:PutObject"],
        Resource = "arn:aws:s3:::terraform-state-0421/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sts_attachment" {
  role       = aws_iam_role.sts_role.name
  policy_arn = aws_iam_policy.sts_policy.arn
}

// aws sts assume-role --role-arn "arn:aws:iam::007638882300:role/sts_role"  --role-session-name "ExampleSession"