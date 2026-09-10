

# 현재 리전의 사용 가능 AZ 이름 리스트. local.azs 가 이걸 씀
data "aws_availability_zones" "available_az" {
  state = "available"
}


# #########################################################################
# 이미지 데이터 선택
# #########################################################################

data "aws_ami" "std11_ec2_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["${local.tag_header}ec2-ami"]
  }
  filter {
    name   = "tag:Owner"
    values = ["std11"]
  }
  filter {
    name   = "tag:Class"
    values = ["bipa17"]
  }
}

# 수업 mysql.tf 는 이미 있는 프라이빗 서브넷을 Name 태그로 조회
data "aws_subnets" "std11_private_subnet_ids" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.std11_vpc.id]
  }

  filter {
    name = "tag:Name"
    values = [
      "${local.tag_header}private1a-subnet",
      "${local.tag_header}private1b-subnet",
      "${local.tag_header}private1c-subnet",
    ]
  }
}
