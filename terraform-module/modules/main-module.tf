# ############################################################
# 루트가 자식 모듈을 조립하는 파일
# source = 폴더 경로. 지금 terraform 을 modules/ 에서 돌리므로 ./network
# 왼쪽 이름 = 자식 variable.tf 의 변수 이름
# 오른쪽 값 = 루트가 넘겨 주는 값
# 새 모듈 추가하면 terraform init 을 다시 해야 함
# ############################################################

module "network" {
  source = "./network"

  az_names         = local.az_names         # data 로 조회한 AZ 리스트
  owner            = local.owner            # 태그/이름 접두사에 씀
  vpc_cidr         = local.vpc_cidr         # VPC 대역. 예: 10.0.0.0/16
  tag_header       = local.tag_header       # "std11-"
  subnet_map       = local.subnet_map       # public/private/cluster 설계도
  eks_cluster_name = local.eks_cluster_name # 서브넷 EKS 태그에 씀
  region           = local.region           # 엔드포인트 이름 com.amazonaws.<region>...
}

# VPC 가 생긴 뒤에 SG 생성. vpc_id 를 network output 에서 받음
module "security" {
  source = "./security"

  tag_header  = local.tag_header
  vpc_id      = module.network.std11_vpc.id # 자식 output 이름.std11_vpc 의 .id
  vpc_cidr    = local.vpc_cidr              # SG 소스용 (8000, DB, NAT all)
  office_cidr = local.office_cidr           # NAT SSH 소스. 학원 공인 IP
}

# 서브넷은 여기서 고름. 키만 바꾸면 됨
# public1a / private1a / cluster1a ...
module "compute" {
  source = "./compute"

  tag_header     = local.tag_header
  vpc_id         = module.network.std11_vpc.id
  vpc_cidr       = local.vpc_cidr
  subnet_id      = module.network.public_subnet_ids["public1a"] # EC2 위치
  efs_subnet_ids = module.network.private_subnet_ids           # EFS 타겟 (AZ당 1)
  ssh_sg_id      = module.security.nat_sg_id                   # 22 (office)
  web_sg_id      = module.security.external_alb_sg_id          # 80/443
  key_name       = "std11-central-key"                         # 기존 키페어
}
