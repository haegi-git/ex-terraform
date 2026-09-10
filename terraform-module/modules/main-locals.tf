# 루트 locals. 여기서 "설계도"를 만들고, 실제 AWS 리소스는 network 모듈이 만듦.
# data / variable 로 받은 값을 가공해서 local.xxx 로 씀.
locals {
  # data 가 조회한 AZ 이름 리스트. 예: ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  az_names = data.aws_availability_zones.available_az.names

  owner    = var.owner
  vpc_cidr = var.vpc_cidr

  # 태그용 접두사. owner 가 std11 이면 "std11-"
  tag_header = var.owner == "" ? "" : "${var.owner}-"

  # "10.0.0.0/16" → "10.0"  (앞에 두 옥텟만. 서브넷 CIDR 만들 때 씀)
  cidr_header = "${split(".", var.vpc_cidr)[0]}.${split(".", var.vpc_cidr)[1]}"

  # 바깥 for: public 한 맵 + private 한 맵  → 리스트 [맵, 맵]
  # 안쪽 for: AZ마다 키 하나 (public1a, private1b ...)
  # merge( ... )  : 맵 여러 개를 키 하나로 합침. for_each 는 맵만 받음
  # ]...          : 리스트를 merge(맵1, 맵2) 처럼 인자로 풀어 넣음
  #
  # idx = 0 public → 세 번째 옥텟 1,2,3
  # idx = 1 private → 11,12,13  (idx * 10 이 간격)
  # i   = AZ 순서 0,1,2  → 같은 타입 안에서 +1
  subnet_map = merge([
    for idx, key in ["public", "private"] : {
      for i, az_name in local.az_names : "${key}${split("-", az_name)[2]}" => {
        type = key
        az   = az_name
        cidr = "${local.cidr_header}.${idx * 10 + i + 1}.0/24"
      }
    }
  ]...)
}

# 디버그할 때 주석 해제해서 terraform output 으로 맵 확인
# output "subnet_map" {
#   value = local.subnet_map
# }
