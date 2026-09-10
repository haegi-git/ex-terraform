# 루트에서 merge 한 맵 하나 → 여기 for_each 하나.
# 리소스 블록은 1개, AWS 서브넷은 키 개수만큼 생김 (public 3 + private 3).
#
# each.key   = "public1a" 같은 맵 키
# each.value = { type, az, cidr } each.value.type
resource "aws_subnet" "this" {
  for_each = var.subnet_map

  vpc_id            = aws_vpc.std11_vpc.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  # type 이 public 일 때만 퍼블릭 IP 자동 할당. private 는 false
  map_public_ip_on_launch = each.value.type == "public"

  tags = {
    Name = "${local.tag_header}${each.key}-subnet"
  }
}

# 키 → 서브넷 ID. 다른 모듈에서 특정 서브넷을 집을 때
output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}

output "public_subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id if var.subnet_map[k].type == "public" }
}

output "private_subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id if var.subnet_map[k].type == "private" }
}
