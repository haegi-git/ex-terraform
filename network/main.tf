resource "aws_vpc" "std11_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  instance_tenancy = "default"
  region           = "eu-central-1"
  tags = {
    Name = "std11-vpc"
  }
}


resource "aws_subnet" "std11_public_subnet" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.std11_vpc.id
  cidr_block        = var.subnet_cidr[0][each.key]
  availability_zone = each.key

  map_public_ip_on_launch                     = true
  enable_resource_name_dns_a_record_on_launch = true
  tags = {
    Name = "${local.tag_header}public${split("-", each.key)[length(split("-", each.key)) - 1]}-subnet"
  }
}

resource "aws_subnet" "std11_private_subnet" {
  for_each          = toset(local.azs)
  vpc_id            = aws_vpc.std11_vpc.id
  cidr_block        = var.subnet_cidr[1][each.key]
  availability_zone = each.key

  tags = {
    Name = "${local.tag_header}private${split("-", each.key)[length(split("-", each.key)) - 1]}-subnet"
  }
}

resource "aws_internet_gateway" "std11_igw" {
  vpc_id = aws_vpc.std11_vpc.id

  tags = {
    Name = "${local.tag_header}igw"
  }
}


# NAT Gateway 생성을 위한 EIP 생성
resource "aws_eip" "std11_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${local.tag_header}nat-eip"
  }
}

# NAT Gateway 생성
resource "aws_nat_gateway" "std11_nat_gw" {
  allocation_id = aws_eip.std11_nat_eip.id
  # for_each 서브넷은 .id 가 없음. 퍼블릭 1a에 NAT 하나
  subnet_id = aws_subnet.std11_public_subnet["eu-central-1a"].id
  depends_on = [
    aws_internet_gateway.std11_igw
  ]
  tags = {
    Name = "${local.tag_header}nat-gw"
  }
}


resource "aws_route_table" "std11_public_rt" {
  vpc_id = aws_vpc.std11_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.std11_igw.id
  }

  tags = {
    Name = "${local.tag_header}public-rt"
  }
}

# 퍼블릭 서브넷 3개를 위 RT에 연결. 이거 없으면 IGW 라우트가 안 탐
resource "aws_route_table_association" "std11_public_rt_assoc" {
  for_each       = aws_subnet.std11_public_subnet
  subnet_id      = each.value.id
  route_table_id = aws_route_table.std11_public_rt.id
}

# 프라이빗: AZ마다 RT. 인터넷은 NAT로만
resource "aws_route_table" "std11_private_rt" {
  for_each = toset(local.azs)
  vpc_id   = aws_vpc.std11_vpc.id

  tags = {
    Name = "${local.tag_header}private-${each.key}-rt"
  }
}

resource "aws_route_table_association" "std11_private_rt_assoc" {
  for_each       = toset(local.azs)
  subnet_id      = aws_subnet.std11_private_subnet[each.key].id
  route_table_id = aws_route_table.std11_private_rt[each.key].id
}

resource "aws_route" "std11_private_rt_route" {
  for_each               = toset(local.azs)
  route_table_id         = aws_route_table.std11_private_rt[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  # NAT 은 gateway_id(IGW용) 가 아니라 nat_gateway_id
  nat_gateway_id         = aws_nat_gateway.std11_nat_gw.id
}
