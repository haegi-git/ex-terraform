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

resource "aws_security_group" "std11_mysql_sg" {
  name        = "${local.tag_header}mysql-sg"
  description = "Security group for MySQL access"
  vpc_id      = aws_vpc.std11_vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
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
    Name = "${local.tag_header}mysql-sg"
  }
}

# 프라이빗 웹. ingress 는 아래 rule 로 외부 ALB SG 만 허용
resource "aws_security_group" "std11_internal_alb_sg" {
  name        = "${local.tag_header}internal-alb-sg"
  description = "Security group for private web access"
  vpc_id      = aws_vpc.std11_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.tag_header}internal-alb-sg"
  }
}

resource "aws_security_group_rule" "std11_internal_alb_rule" {
  type      = "ingress"
  from_port = 80
  to_port   = 80
  protocol  = "tcp"

  source_security_group_id = aws_security_group.std11_external_alb_sg.id
  security_group_id        = aws_security_group.std11_internal_alb_sg.id
}
