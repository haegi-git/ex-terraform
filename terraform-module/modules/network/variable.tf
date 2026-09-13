# 왼쪽 이름 = main-module.tf 의 module "network" { 여기 = ... }
# default 가 있어도 루트에서 넘기는 값이 우선

variable "owner" {
  description = "owner name"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = ""
}

variable "tag_header" {
  description = "tag prefix"
  type        = string
  default     = ""
}

variable "az_names" {
  description = "AZ names"
  type        = list(string)
  default     = []
}

# 네트워크 모듈은 VPC 를 직접 만듦. 이 값은 예비용, 지금은 안 써도 됨
variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = ""
}

# 엔드포인트 서비스 이름: com.amazonaws.<region>.ecr.api
variable "region" {
  description = "AWS region"
  type        = string
  default     = ""
}

# 키 예: public1a. 값: { type, az, cidr }
variable "subnet_map" {
  description = "subnet map"
  type = map(object({
    type = string
    az   = string
    cidr = string
  }))
}

variable "eks_cluster_name" {
  description = "EKS cluster name"
  type        = string
}
