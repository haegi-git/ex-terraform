# 루트가 밖에서 받는 입력. terraform.tfvars 또는 default
# 모듈에 넘기는 구멍은 여기가 아니라 각 모듈 variable.tf

variable "owner" {
  description = "owner name"
  type        = string
  default     = "std11" # 안 넣으면 이 값. 태그/이름에 씀
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16" # VPC 전체 대역. 서브넷은 이 안에서 자름
}

# NAT SSH 소스. 학원 공인 IP 알면 "x.x.x.x/32"
variable "office_cidr" {
  description = "office CIDR"
  type        = string
  default     = "0.0.0.0/0" # 전 세계. 수업용 기본값
}
