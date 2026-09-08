# 수업이랑 같이 SG를 역할별로 나눔. 같은 폴더라 compute.tf 에서 .id 로 참조

resource "aws_security_group" "std11_ssh_sg" {
  name        = "${local.tag_header}ssh-sg"
  description = "Security group for SSH access"
  vpc_id      = aws_vpc.std11_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}ssh-sg"
  }
}

resource "aws_security_group" "std11_external_alb_sg" {
  name        = "${local.tag_header}external-alb-sg"
  description = "Security group for web access"
  vpc_id      = aws_vpc.std11_vpc.id

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

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}external-alb-sg"
  }
}
