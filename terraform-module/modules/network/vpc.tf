# VPC = 우리 전용 사설 네트워크. 서브넷/IGW/SG 가 전부 여기 안에 들어감
resource "aws_vpc" "std11_vpc" {
  cidr_block           = var.vpc_cidr # 전체 주소 대역. 예: 10.0.0.0/16
  enable_dns_hostnames = true         # 인스턴스에 DNS 이름 부여
  enable_dns_support   = true         # VPC 안에서 DNS 조회 허용 (엔드포인트에 필요)

  instance_tenancy = "default" # 공유 하드웨어. dedicated 는 비쌈
  region           = "eu-central-1"
  tags = {
    Name = "${local.owner}-vpc"
  }
}

# VPC 객체 통째로 내보냄. 루트에서 module.network.std11_vpc.id / .cidr_block
output "std11_vpc" {
  value = aws_vpc.std11_vpc
}
