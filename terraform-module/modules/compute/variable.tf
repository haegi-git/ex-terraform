# 자식 모듈의 "구멍". 실제 값은 루트 main-module.tf 왼쪽=오른쪽 으로 채움
# type        = 어떤 종류의 값인지 (string, map, list ...)
# description = 설명. AWS 로 안 넘어감
# default     = 안 넘기면 쓰는 기본값. 없으면 무조건 넘겨야 함

variable "tag_header" {
  type        = string
  description = "tag prefix"
}

variable "vpc_id" {
  type        = string
  description = "VPC id"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR"
}

# EC2 한 대는 서브넷 하나만 받음. 리스트 아님
variable "subnet_id" {
  type        = string
  description = "EC2 subnet"
}

# EFS 마운트 타겟은 AZ마다 필요 → 서브넷 ID 맵
variable "efs_subnet_ids" {
  type        = map(string)
  description = "EFS mount target subnets"
}

variable "ssh_sg_id" {
  type        = string
  description = "SSH security group"
}

variable "web_sg_id" {
  type        = string
  description = "web security group"
}

variable "key_name" {
  type        = string
  description = "EC2 key pair"
  default     = "std11-central-key" # AWS 에 이 이름이 있어야 함
}
