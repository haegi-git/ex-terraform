# output = 이 모듈 밖으로 내보내는 값
# 루트에서 module.compute.instance_id 처럼 꺼냄

output "instance_id" {
  value = aws_instance.this.id
}

output "private_ip" {
  value = aws_instance.this.private_ip
}

output "efs_id" {
  value = aws_efs_file_system.this.id
}
