# AWS 에 이미 있는 정보를 조회. 리소스를 만들지 않음.
data "aws_region" "current" {}

# 이 리전에서 사용 가능한 AZ 이름 리스트 → local.az_names
data "aws_availability_zones" "available_az" {
  state = "available"
}
