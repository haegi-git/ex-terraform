# 이 폴더(루트)가 밖에서 받는 입력. terraform.tfvars 또는 default.
# 모듈에 넘기는 구멍은 여기가 아니라 network/variable.tf 임.
variable "owner" {
  description = "사용자 계정 명"
  type        = string
  default     = "std11"
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = "10.0.0.0/16"
}
