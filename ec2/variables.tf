variable "namespace" {
  description = "the project namespace to use for unique resource naming"
  type        = string
  default     = "ec2"
}
variable "environment" {
  description = "environment to deploy the resources"
  type        = string
  default     = "dev"
}