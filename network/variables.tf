# variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the subnet"
  type        = list(map(string))
  default = [
    {
      eu-central-1a = "10.0.1.0/24",
      eu-central-1b = "10.0.2.0/24",
      eu-central-1c = "10.0.3.0/24"
    },
    {
      eu-central-1a = "10.0.11.0/24",
      eu-central-1b = "10.0.12.0/24",
      eu-central-1c = "10.0.13.0/24"
    }
  ]
}

variable "default_name" {
  description = "Default name for resources"
  type        = string
  default     = "std11"
}

variable "db_username" {
  description = "RDS MySQL master username"
  type        = string
  default     = "haegi"
}

variable "db_password" {
  description = "RDS MySQL master password"
  type        = string
  default     = "88072713"
  sensitive   = true
}

# 수업이랑 같이 ARN 문자열을 그대로 넣음. eu-central-1 인증서여야 함
variable "acm_certificate_arn" {
  description = "ACM certificate ARN in eu-central-1"
  type        = string
}
