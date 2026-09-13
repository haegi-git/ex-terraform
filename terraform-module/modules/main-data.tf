# data = AWS 에 이미 있는 정보 조회. 리소스를 만들지 않음
# current 는 기본 provider 리전을 따라감. 지금은 eu-central-1

data "aws_region" "current" {}
# .name 은 deprecated. 값 자체는 "eu-central-1"
# 쓸 때: data.aws_region.current.name  또는  .region

# 이 리전에서 지금 쓸 수 있는 AZ 이름 리스트
data "aws_availability_zones" "available_az" {
  state = "available" # available | unavailable. 꺼진 AZ 제외
}
