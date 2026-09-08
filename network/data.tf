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
