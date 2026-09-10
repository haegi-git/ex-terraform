# 루트가 자식 모듈을 "호출"하는 파일.
# source = 모듈 폴더 경로. 지금 terraform 을 modules/ 에서 돌리므로 ./network
# 왼쪽 이름 = network/variable.tf 의 variable 이름 (자식이 받는 구멍)
# 오른쪽 값 = 루트가 넘겨 주는 값 (대부분 local)
module "network" {
  source = "./network"

  az_names   = local.az_names
  owner      = local.owner
  vpc_cidr   = local.vpc_cidr
  tag_header = local.tag_header
  subnet_map = local.subnet_map
}

# 자식 output 은 module.<이름>.<output이름> 으로 꺼냄
# output "vpc_id" {
#   value = module.network.std11_vpc.id
# }
