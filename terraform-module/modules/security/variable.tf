# 값은 루트 main-module.tf 에서 채움. default="" 는 구멍만 연 것
variable "tag_header" {
  type        = string
  description = "tag prefix"
  default     = ""
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
  default     = ""
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
  default     = ""
}

# NAT 22번 소스. 루트 office_cidr 을 그대로 받음
variable "office_cidr" {
  type        = string
  description = "office CIDR"
  default     = "0.0.0.0/0"
}
