# ############################################################
# EFS = 여러 EC2 가 같이 쓰는 네트워크 디스크
# 파일 시스템 1개 + AZ마다 마운트 타겟 1개
# EC2 는 user_data 에서 이 파일 시스템을 /mnt/efs 에 붙임
# ############################################################

# EFS 자체도 SG 가 필요함. NFS 포트 2049
resource "aws_security_group" "efs" {
  name        = "${var.tag_header}efs-sg"
  description = "NFS from VPC to EFS" # AWS 필드는 영어만
  vpc_id      = var.vpc_id            # 어느 VPC 에 붙일지

  # ingress = 들어오는 트래픽. VPC 안에서만 2049 허용
  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr] # 리스트여야 함. 예: ["10.0.0.0/16"]
  }
  # egress = 나가는 트래픽. -1 / 포트 0 = All traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.tag_header}efs-sg" }
}

resource "aws_efs_file_system" "this" {
  creation_token = "${var.tag_header}efs" # 같은 계정에서 이름 충돌 막기용 토큰
  encrypted      = true                   # 디스크 암호화

  tags = { Name = "${var.tag_header}efs" }
}

# 마운트 타겟 = 그 AZ 서브넷에서 EFS 로 들어가는 문
# 인스턴스와 같은 AZ 에 타겟이 있어야 마운트가 됨
resource "aws_efs_mount_target" "this" {
  for_each = var.efs_subnet_ids # 예: { private1a = "subnet-xxx", ... }

  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = each.value                 # 맵의 값 = 서브넷 ID
  security_groups = [aws_security_group.efs.id]
}
