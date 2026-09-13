# ############################################################
# VPC 엔드포인트 = 인터넷(NAT) 안 거치고 AWS 서비스로 가는 길
# S3 Gateway  → 라우트 테이블에 붙음 (서브넷 없음. 콘솔 서브넷 칸이 비는 게 정상)
# ECR Interface → 서브넷에 ENI 생성. AZ당 서브넷 1개만
# ############################################################

# 이 리전의 S3 Gateway 서비스 이름 조회 (com.amazonaws.eu-central-1.s3)
data "aws_vpc_endpoint_service" "s3" {
  service      = "s3"
  service_type = "Gateway" # Gateway | Interface
}

resource "aws_vpc_endpoint" "s3_endpoint" {
  vpc_id            = aws_vpc.std11_vpc.id
  service_name      = data.aws_vpc_endpoint_service.s3.service_name
  vpc_endpoint_type = "Gateway"
  # public RT 제외. private 3 + cluster 1
  route_table_ids = concat(
    [for rt in aws_route_table.private : rt.id],
    [aws_route_table.cluster.id]
  )
  tags = {
    Name = "${var.tag_header}s3-endpoint"
  }
}

# Interface 엔드포인트용 SG. ECR 은 443
resource "aws_security_group" "vpce" {
  name        = "${var.tag_header}vpce-sg"
  description = "Interface VPC endpoint (ECR 443)"
  vpc_id      = aws_vpc.std11_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}vpce-sg" }
}

locals {
  # public 제외한 뒤, 같은 AZ 는 하나로
  # ...  = 같은 키(AZ)를 리스트로 묶음
  # ids[0] = 그 AZ 에서 첫 서브넷만 (Interface 는 AZ당 1개)
  non_public_subnet_ids = [
    for az, ids in {
      for k, s in aws_subnet.this : var.subnet_map[k].az => s.id...
      if var.subnet_map[k].type != "public"
    } : ids[0]
  ]
}

# ecr.api = 레포 조회/로그인 같은 API
# ecr.dkr = 이미지 pull/push
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.std11_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.non_public_subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true # 원래 ECR DNS 로 접속해도 이 엔드포인트로 감
  tags = {
    Name = "${var.tag_header}ecr-api-endpoint"
  }
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.std11_vpc.id
  service_name        = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = local.non_public_subnet_ids
  security_group_ids  = [aws_security_group.vpce.id]
  private_dns_enabled = true
  tags = {
    Name = "${var.tag_header}ecr-dkr-endpoint"
  }
}
