resource "aws_vpc" "std11_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  instance_tenancy = "default"
  region           = "eu-central-1"
  tags = {
    Name = "${local.owner}-vpc"
  }
}

# 통째로 내보내면 루트에서 module.network.std11_vpc.id 처럼 속성을 꺼냄
output "std11_vpc" {
  value = aws_vpc.std11_vpc
}
