# 다른 모듈은 SG 리소스가 아니라 ID 만 받음
# 루트: ssh_sg_id = module.security.nat_sg_id

output "nat_sg_id" {
  value = aws_security_group.std11_nat_sg.id
}

output "internal_ssh_sg_id" {
  value = aws_security_group.std11_internal_ssh_sg.id
}

output "external_alb_sg_id" {
  value = aws_security_group.std11_external_alb_sg.id
}

output "internal_alb_sg_id" {
  value = aws_security_group.std11_internal_alb_sg.id
}

# for_each SG 는 맵으로 내보냄. 예: module.security.db_sg_ids["mysql"]
output "db_sg_ids" {
  value = { for k, sg in aws_security_group.std11_db_sg : k => sg.id }
}

output "eks_node_sg_id" {
  value = aws_security_group.std11_eks_node_sg.id
}

output "cluster_sg_id" {
  value = aws_security_group.std11_cluster_sg.id
}
