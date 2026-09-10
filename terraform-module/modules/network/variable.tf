# 자식 모듈이 루트로부터 받는 입력.
# main-module.tf 의 module "network" { 여기이름 = ... } 과 이름이 같아야 함.

variable "owner" {
  description = "사용자 계정 명"
  type        = string
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR 블록"
  type        = string
  default     = ""
}

variable "tag_header" {
  description = "태그 접두사"
  type        = string
  default     = ""
}

variable "az_names" {
  description = "가용 영역 명"
  type        = list(string)
  default     = []
}

# 루트 local.subnet_map 과 같은 모양. 키 예: public1a, private1b
variable "subnet_map" {
  description = "서브넷 설계도 (type, az, cidr)"
  type = map(object({
    type = string
    az   = string
    cidr = string
  }))
}
