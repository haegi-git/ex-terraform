# 서브넷 방화벽. SG(sg.tf)를 지우는 게 아님 — EC2는 SG, 서브넷은 NACL
# rule_no 작은 것부터 평가. action / rule_no 는 NACL만 있음

resource "aws_network_acl" "std11_public_nacl" {
  vpc_id = aws_vpc.std11_vpc.id

  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  # NACL은 stateless. 응답(에페메랄)도 직접 열어야 함
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${local.tag_header}public-nacl"
  }
}

resource "aws_network_acl_association" "std11_public_nacl_assoc" {
  for_each       = aws_subnet.std11_public_subnet
  subnet_id      = each.value.id
  network_acl_id = aws_network_acl.std11_public_nacl.id
}
