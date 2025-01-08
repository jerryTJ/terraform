variable "namespace" {
  description = "the project namespace to use for unique resource naming"
  type        = string
  default     = "s3backend"
}
variable "principal_arns" {
  description = "A list of principal arns to allow to assume the role"
  type        = list(string)
  default     = null
}
variable "environment" {
  description = "environment to deploy the resources"
  type        = string
  default     = "dev"
}

variable "force_destroy_state" {
  description = "Force destroy the s3 bucket containing the state file"
  type        = bool
  default     = true
}