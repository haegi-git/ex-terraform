# ############################################################
# EC2
# 수업 기준: t3.nano / 루트 8GiB + 추가 5GiB / 웹+SSH SG
# 서브넷은 루트 main-module.tf 의 subnet_id 로 고름
# 첫 부팅 때 user_data 로 패키지 설치 + EFS 마운트
# ############################################################

# data = 새로 만들지 않고 AWS 에 이미 있는 걸 조회
data "aws_ami" "al2023" {
  most_recent = true          # 조건에 맞는 것 중 가장 최신 AMI
  owners      = ["amazon"]    # 공식 Amazon 이미지. 아무 AMI 나 쓰면 보안/리전 문제

  # filter 여러 개면 AND. 이름에 al2023 + x86_64 가 들어간 것만
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]          # 지금 EC2 가 쓰는 가상화 방식
  }
}

resource "aws_instance" "this" {
  ami           = data.aws_ami.al2023.id # 위에서 찾은 OS 이미지 ID
  instance_type = "t3.nano"              # CPU/메모리 크기. nano 가 가장 작음
  key_name      = var.key_name           # SSH 할 때 쓰는 키페어 이름 (이미 AWS 에 있어야 함)
  subnet_id     = var.subnet_id          # 이 인스턴스가 들어갈 서브넷 1개

  # SG 여러 개 붙일 수 있음. 웹(80/443) + SSH(22)
  vpc_security_group_ids = [var.ssh_sg_id, var.web_sg_id]

  # 루트 볼륨 = OS 가 설치되는 기본 디스크
  root_block_device {
    volume_size           = 8     # GiB. 수업 기본값
    volume_type           = "gp3" # 범용 SSD. gp2 보다 보통 저렴
    delete_on_termination = true  # 인스턴스 지우면 디스크도 같이 삭제
  }

  # 추가 EBS. 루트와 별도 디스크 5GiB
  ebs_block_device {
    device_name           = "/dev/sdf" # 리눅스에서 보이는 장치 이름
    volume_size           = 5
    volume_type           = "gp3"
    delete_on_termination = true
  }

  # 첫 부팅 때 한 번 실행되는 스크립트
  # <<-EOF 는 앞에 탭을 지움. #!/bin/bash 앞에 공백 있으면 실행 안 됨
  user_data = <<-EOF
#!/bin/bash
dnf update -y
dnf install -y docker docker-compose-plugin curl unzip amazon-efs-utils
systemctl enable --now docker
usermod -aG docker ec2-user

mkdir -p /mnt/efs
# EFS 마운트 타겟이 아직 안 떴으면 몇 초 기다렸다가 재시도
until mount -t efs -o tls ${aws_efs_file_system.this.id}:/ /mnt/efs; do
  sleep 5
done
# 재부팅 후에도 다시 붙도록 /etc/fstab 에 등록
echo "${aws_efs_file_system.this.id}:/ /mnt/efs efs _netdev,tls 0 0" >> /etc/fstab
EOF

  # user_data 보다 마운트 타겟이 먼저 끝나야 함
  depends_on = [aws_efs_mount_target.this]

  tags = { Name = "${var.tag_header}ec2" }
}
