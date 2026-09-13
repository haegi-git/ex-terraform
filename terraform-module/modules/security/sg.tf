# ############################################################
# 보안 그룹 = 가상 방화벽. Name 태그는 수업 표와 맞춤
#
# 공통 옵션
#   vpc_id      : 어느 VPC 소속인지. SG 는 VPC 없이 못 만듦
#   description : AWS 콘솔 설명. 영어만 (한글이면 에러)
#   ingress     : 들어오는 허용. from_port / to_port / protocol / 소스
#   egress      : 나가는 허용. 보통 All (protocol -1, 포트 0)
#   소스        : cidr_blocks 또는 security_groups (둘 중 하나)
#   All traffic : protocol = "-1", from_port = 0, to_port = 0
# ############################################################

# NAT / bastion
# 22=office  /  80,443=인터넷  /  all=VPC 안
resource "aws_security_group" "std11_nat_sg" {
  name        = "${var.tag_header}nat-sg"
  description = "Security group for NAT or bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.office_cidr] # 학원 공인 IP. 모르면 0.0.0.0/0
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}nat-sg" }
}

# 프라이빗 서버 SSH. 인터넷이 아니라 nat-sg 에서만 22
resource "aws_security_group" "std11_internal_ssh_sg" {
  name        = "${var.tag_header}internal-ssh-sg"
  description = "SSH from NAT or bastion"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.std11_nat_sg.id] # CIDR 대신 다른 SG
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}internal-ssh-sg" }
}

# 외부 ALB. 인터넷 → 80/443/8000
resource "aws_security_group" "std11_external_alb_sg" {
  name        = "${var.tag_header}external-alb-sg"
  description = "Security group for external ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}external-alb-sg" }
}

# 내부 ALB. 80/443 은 외부 ALB SG 만, 8000 은 VPC CIDR
resource "aws_security_group" "std11_internal_alb_sg" {
  name        = "${var.tag_header}internal-alb-sg"
  description = "Security group for internal ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.std11_external_alb_sg.id]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.std11_external_alb_sg.id]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}internal-alb-sg" }
}

# DB 포트만 다르므로 for_each. each.key=이름, each.value=포트
locals {
  db_ports = {
    mysql      = 3306
    mariadb    = 3306
    postgresql = 5432
    oracle     = 1521
    mssql      = 1433
    redis      = 6379
  }
}

resource "aws_security_group" "std11_db_sg" {
  for_each = local.db_ports

  name        = "${var.tag_header}internal-${each.key}-sg"
  description = "Security group for ${each.key}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = each.value
    to_port     = each.value
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}internal-${each.key}-sg" }
}

# EKS 워커
# 80/443 = 외부 ALB  /  all + self = 노드끼리
# 10250 은 아래 rule 로 분리 (cluster_sg 와 서로 참조하면 순환)
resource "aws_security_group" "std11_eks_node_sg" {
  name        = "${var.tag_header}eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.std11_external_alb_sg.id]
  }
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.std11_external_alb_sg.id]
  }
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true # 이 SG 가 붙은 ENI 끼리
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}eks-node-sg" }
}

# EKS 컨트롤 플레인 API. 443 = 노드 SG + 인터넷(또는 office CIDR)
resource "aws_security_group" "std11_cluster_sg" {
  name        = "${var.tag_header}cluster-sg"
  description = "Security group for EKS cluster API"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.std11_eks_node_sg.id]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}cluster-sg" }
}

# kubelet(10250). 리소스 안이 아니라 별도 rule 이라 순환이 안 남
resource "aws_security_group_rule" "std11_eks_node_kubelet" {
  type                     = "ingress"
  from_port                = 10250
  to_port                  = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.std11_eks_node_sg.id # 규칙이 붙는 SG
  source_security_group_id = aws_security_group.std11_cluster_sg.id  # 소스 SG
}
