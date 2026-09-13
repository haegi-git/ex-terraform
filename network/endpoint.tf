# ############################################################
# S3 Endpoint 설정 : VPC 내에서 S3 서비스에 대한 프라이빗 액세스를 제공하는 gateway 엔드포인트 생성
# ############################################################
# 1. 서비스 데이터 소스 정의(서비스 정의)
data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway"

}
# 2. 엔드포인트 생성 및 연결(엔드포인트 생성)
resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.std11_vpc.id
  service_name      = data.aws_vpc_endpoint_service.s3.service_name
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [for az in local.azs : aws_route_table.std11_private_rt[az].id]
  tags = {
    Name = "s3-endpoint"
  }
}

# ############################################################
# ECR 서비스 사용을 위한 interface endpoint 설정
# - ECR API Interface Endpoint
#   IAM 인증, 이미지 메타데이터 조회, 레포지토리 ㅐㅇ성 및 삭제 등 ECR API 제어 명령을 처리
#   com.amazonaws.<region>.ecr.api
# - ECR DKR Interface Endpoint
#   실제 docker 데몬이 container image layer를 가져오거나 pull/push 작업을 수행하는 데 사용
#   com.amazonaws.<region>.ecr.dkr
# ############################################################

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.std11_vpc.id
  service_name      = "com.amazonaws.${local.region}.ecr.api"
  vpc_endpoint_type = "Interface"

  # local.azs = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  # for az in ...  → az 에 1a, 1b, 1c 를 순서대로 넣음
  # aws_subnet.std11_private_subnet[az].id  → for_each 서브넷 맵에서 그 AZ 키의 ID
  # [ ... ] 로 감싸서 ["subnet-aaa", "subnet-bbb", "subnet-ccc"] 리스트가 됨
  # Interface VPCE 는 ENI 를 이 서브넷들에 만듦 (Gateway 의 route_table_ids 와 같은 반복)
  subnet_ids = [for az in local.azs : aws_subnet.std11_private_subnet[az].id]

  # ecr은 통신포트로 443을 사용
  security_group_ids = [aws_security_group.std11_external_alb_sg.id]
  # [필수] ecr의 기본 url 주소 호환을 위한 필수 옵션
  private_dns_enabled = true
  tags = {
    Name = "ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.std11_vpc.id
  service_name        = "com.amazonaws.${local.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [for az in local.azs : aws_subnet.std11_private_subnet[az].id]
  security_group_ids  = [aws_security_group.std11_external_alb_sg.id]
  private_dns_enabled = true
  tags = {
    Name = "ecr-dkr-endpoint"
  }
}
