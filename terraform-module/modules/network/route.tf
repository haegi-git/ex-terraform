# ############################################################
# 라우트 테이블 = "이 서브넷에서 나가는 길"
# public 1개 / private AZ별 3개 / cluster 1개
# this 하나로 subnet_map 을 돌리면 RT 가 9개 생김 → 종류별로 나눔
# ############################################################

# for_each 없음 = 딱 1개. 퍼블릭 서브넷 3개가 이걸 같이 씀
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.std11_vpc.id
  tags   = { Name = "${var.tag_header}public-route-table" }
}

# private 만 골라서 3개. 키 예: private1a
resource "aws_route_table" "private" {
  for_each = { for k, v in var.subnet_map : k => v if v.type == "private" }

  vpc_id = aws_vpc.std11_vpc.id
  tags   = { Name = "${var.tag_header}${each.key}-route-table" }
}

resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.std11_vpc.id
  tags   = { Name = "${var.tag_header}cluster-route-table" }
}

# IGW = VPC 와 인터넷을 연결. 퍼블릭 서브넷만 이걸 씀
resource "aws_internet_gateway" "std11_igw" {
  vpc_id = aws_vpc.std11_vpc.id
  tags   = { Name = "${var.tag_header}igw" }
}

# NAT 가 쓸 고정 공인 IP. domain = "vpc" 는 VPC용 EIP 라는 뜻
resource "aws_eip" "std11_nat_eip" {
  domain = "vpc"
  tags   = { Name = "${var.tag_header}nat-eip" }
}

# NAT = private/cluster 가 인터넷 나갈 때 쓰는 출구
# subnet_id 는 문자열 하나. 퍼블릭 서브넷에 둬야 인터넷과 붙음
resource "aws_nat_gateway" "std11_nat_gw" {
  allocation_id = aws_eip.std11_nat_eip.id    # EIP 의 allocation ID
  subnet_id     = aws_subnet.this["public1a"].id
  depends_on    = [aws_internet_gateway.std11_igw] # IGW 먼저

  tags = { Name = "${var.tag_header}nat-gw" }
}

# 0.0.0.0/0 = 기본 경로(그 밖 전부)
# 퍼블릭은 IGW 로, private/cluster 는 NAT 로
resource "aws_route" "public" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.std11_igw.id # IGW 일 때
}

resource "aws_route" "private" {
  for_each = { for k, v in var.subnet_map : k => v if v.type == "private" }

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.std11_nat_gw.id # NAT 일 때. gateway_id 아님
}

resource "aws_route" "cluster" {
  route_table_id         = aws_route_table.cluster.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.std11_nat_gw.id
}

# association = 서브넷 1개 ↔ 라우트 테이블 1개
# subnet_id 는 리스트 금지. ID 는 var.subnet_map 이 아니라 aws_subnet.this[키]
resource "aws_route_table_association" "public" {
  for_each = { for k, v in var.subnet_map : k => v if v.type == "public" }

  route_table_id = aws_route_table.public.id # 3개 서브넷이 같은 RT
  subnet_id      = aws_subnet.this[each.key].id
}

resource "aws_route_table_association" "private" {
  for_each = { for k, v in var.subnet_map : k => v if v.type == "private" }

  route_table_id = aws_route_table.private[each.key].id # AZ마다 자기 RT
  subnet_id      = aws_subnet.this[each.key].id
}

resource "aws_route_table_association" "cluster" {
  for_each = { for k, v in var.subnet_map : k => v if v.type == "cluster" }

  route_table_id = aws_route_table.cluster.id
  subnet_id      = aws_subnet.this[each.key].id
}
