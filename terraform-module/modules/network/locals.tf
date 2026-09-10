# 자식 안에서 var.xxx 를 짧게 쓰려고 복사. 필수는 아님.
# 서브넷 맵은 var.subnet_map 을 그대로 for_each 에 넣음.
locals {
  owner      = var.owner
  vpc_cidr   = var.vpc_cidr
  tag_header = var.tag_header
  az_names   = var.az_names
}
