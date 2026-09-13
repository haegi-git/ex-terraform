# ############################################################
# 서브넷 9개 = 루트 subnet_map 을 for_each 한 번
# each.key   = "public1a" / "private1b" / "cluster1c"
# each.value = { type, az, cidr }
# ############################################################
resource "aws_subnet" "this" {
  for_each = var.subnet_map

  vpc_id            = aws_vpc.std11_vpc.id # 어느 VPC 소속인지
  cidr_block        = each.value.cidr      # 이 서브넷 대역. 예: 10.0.1.0/24
  availability_zone = each.value.az        # 예: eu-central-1a

  # public 만 퍼블릭 IPv4 자동 할당. private/cluster 는 false
  map_public_ip_on_launch = each.value.type == "public"

  # 호스트이름을 IP 가 아니라 리소스 이름으로, DNS A 레코드 켜기
  private_dns_hostname_type_on_launch         = "resource-name"
  enable_resource_name_dns_a_record_on_launch = true

  # merge = 맵 여러 개를 하나로. 조건이 아니면 빈 맵 {}
  tags = merge(
    {
      Name = "${local.tag_header}${each.key}-subnet"
    },
    # 외부 NLB/ALB 가 쓸 퍼블릭 서브넷
    each.value.type == "public" ? {
      "kubernetes.io/role/elb"                        = "1"
      "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    } : {},
    # 내부 NLB/ALB 가 쓸 클러스터 서브넷
    each.value.type == "cluster" ? {
      "kubernetes.io/role/internal-elb"               = "1"
      "kubernetes.io/cluster/${var.eks_cluster_name}" = "owned"
    } : {}
  )
}

# 루트/다른 모듈에서 꺼내기 쉽게 종류별로 ID 맵
output "subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id }
}

output "public_subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id if var.subnet_map[k].type == "public" }
}

output "private_subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id if var.subnet_map[k].type == "private" }
}

output "cluster_subnet_ids" {
  value = { for k, s in aws_subnet.this : k => s.id if var.subnet_map[k].type == "cluster" }
}
