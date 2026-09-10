# ############################################################
# EKS 구동 프로세스
# ############################################################

# ############################################################
# eks 및 워커노드를 위한 보안 그룹 생성
# ############################################################
# 노드와 컨트롤 플레인 간 통신을 위한 보안 그룹 생성 포트 22(ssh), 443(https), 10250(kubelet api)
# 노드간 통신 모두 허용
resource "aws_security_group" "std11_eks_sg" {
  name        = "${local.tag_header}eks-sg"
  description = "EKS and worker node security group"
  vpc_id      = aws_vpc.std11_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All traffic"
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Kubelet API access"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All traffic"
  }
  tags = {
    Name = "${local.tag_header}eks-sg"
  }
}
# ############################################################
# k8s master 및 워커 노드용 역할 및 정책 생성
# ############################################################
# 클러스터k8s용 역할 생성

resource "aws_iam_role" "std11_eks_master_role" {
  name = "${local.tag_header}eks-master-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

# 역할에서 사용할 정책 생성
# AmazonEKSClusterPolicy : EKS 클러스터 정책(전체 권한) 콘솔에서 iam - 정책 - AmazonEKSClusterPolicy 참조
resource "aws_iam_role_policy_attachment" "std11_eks_master_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.std11_eks_master_role.id
}

# 워커노드용 역할 및 정책
resource "aws_iam_role" "std11_eks_node_role" {
  name = "${local.tag_header}eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "std11_eks_node_policy_attachment" {
  for_each   = toset(local.node_policies)
  policy_arn = each.value
  role       = aws_iam_role.std11_eks_node_role.id
}

# ############################################################
# eks cluster 리소스 생성
# ############################################################

resource "aws_eks_cluster" "std11_eks_cluster" {
  name = "${local.tag_header}eks-cluster"
  # version 넣지 않음. 이미 최신이면 1.35 로 내리는 건 롤백이라 AWS 가 막음
  role_arn = aws_iam_role.std11_eks_master_role.arn
  # 네트워크 설정
  vpc_config {
    subnet_ids = [for subnet in aws_subnet.std11_private_subnet : subnet.id]
  }

  # 사용자 연결 설정
  access_config {
    # EKS 클러스터가 사용자나 역할을 어떤 방식으로 인식하게 할지 설정
    # API_AND_CONFIG_MAP : 클러스터 역할 및 설정 맵을 사용
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }
  depends_on = [aws_iam_role_policy_attachment.std11_eks_master_policy_attachment]
  tags = {
    Name = "${local.tag_header}eks-cluster"
  }

  lifecycle {
    ignore_changes = [version]
  }
}

# 선생님이 하신 것: 클러스터 SG 에 "노드 SG 에서 443 허용" 규칙 추가
# LT 에 커스텀 SG 만 있으면 컨트롤플레인이 워커를 모름
resource "aws_security_group_rule" "std11_eks_cluster_from_nodes" {
  type                     = "ingress"
  description              = "Allow worker nodes to cluster API"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.std11_eks_cluster.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.std11_eks_sg.id
}

# ############################################################
# 노드 그룹 구성
# ############################################################
data "aws_ami" "eks_al2023_latest" {
  most_recent = true
  owners      = ["602401143452"] # Amazon EKS 공식 계정

  filter {
    name = "name"
    # 'standard'를 명시하는 대신 와일드카드를 써서 1.35 버전의 x86_64 이미지를 찾습니다.
    values = ["amazon-eks-node-al2023-x86_64-standard-${aws_eks_cluster.std11_eks_cluster.version}-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "std11_eks_node_launch_template" {
  # 생성할 인스턴스들에 부여할 이름의 접두사
  name_prefix   = "${local.tag_header}eks-node-launch-template-"
  image_id      = data.aws_ami.eks_al2023_latest.id
  instance_type = "t3.small"
  key_name      = "std11-central-key"
  # LT 에 SG 만 넣으면 EKS 클러스터 SG 가 안 붙어서 노드가 API 에 못 감
  vpc_security_group_ids = [
    aws_eks_cluster.std11_eks_cluster.vpc_config[0].cluster_security_group_id,
    aws_security_group.std11_eks_sg.id,
    aws_security_group.std11_ssh_sg.id,
  ]

  update_default_version = true
  # AL2023 NodeConfig. --- 앞에 공백 있으면 YAML 파싱 실패
  user_data = base64encode(<<-EOT
---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${aws_eks_cluster.std11_eks_cluster.name}
    apiServerEndpoint: ${aws_eks_cluster.std11_eks_cluster.endpoint}
    certificateAuthority: ${aws_eks_cluster.std11_eks_cluster.certificate_authority[0].data}
    cidr: ${aws_eks_cluster.std11_eks_cluster.kubernetes_network_config[0].service_ipv4_cidr}
EOT
  )
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${local.tag_header}eks-node-launch-template"
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags = {
      Name = "${local.tag_header}eks-node-launch-template-volume"
    }
  }
}


# ############################################################
# 노드 그룹 생성
# ############################################################

resource "aws_eks_node_group" "std11_eks_node_group" {
  node_group_name = "${local.tag_header}eks-node-group"
  cluster_name    = aws_eks_cluster.std11_eks_cluster.name

  node_role_arn = aws_iam_role.std11_eks_node_role.arn
  subnet_ids    = [for subnet in aws_subnet.std11_private_subnet : subnet.id]
  ami_type      = "CUSTOM"
  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }
  launch_template {
    id      = aws_launch_template.std11_eks_node_launch_template.id
    version = aws_launch_template.std11_eks_node_launch_template.latest_version
  }
  depends_on = [aws_iam_role_policy_attachment.std11_eks_node_policy_attachment]
}


# ############################################################
# [추가] 사용자 연결 설정
# ############################################################

resource "null_resource" "std11_eks_user_connection" {
  depends_on = [aws_eks_node_group.std11_eks_node_group]
  provisioner "local-exec" {
    command = "aws eks update-kubeconfig --region ${local.region} --name ${aws_eks_cluster.std11_eks_cluster.name}"
  }
}


# ############################################################
# 사용자 등록
# ############################################################

# resource "aws_eks_access_entry" "bipa17-student11" {
#   cluster_name = aws_eks_cluster.std11_eks_cluster.name

#   principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/bipa17-student11"

#   kubernetes_groups = ["master"]
#   type              = "STANDARD"

# }


# resource "aws_eks_access_policy_association" "bipa17-student11-policy-association" {
#   cluster_name  = aws_eks_cluster.std11_eks_cluster.name
#   policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
#   principal_arn = aws_eks_access_entry.bipa17-student11.principal_arn
#   access_scope {
#     type = "CLUSTER"
#   }
#   depends_on = [aws_eks_cluster.std11_eks_cluster]
# }
