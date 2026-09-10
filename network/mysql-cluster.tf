# ############################################################
# lambda function에서 사용할 보안 그룹
# ############################################################
resource "aws_security_group" "std11_lambda_sg" {
  name        = "${local.tag_header}lambda-sg"
  description = "Allow inbound traffic from the internet"
  vpc_id      = aws_vpc.std11_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${local.tag_header}lambda-sg"
  }
}


# ############################################################
# 보안 암호 생성
# 아래는 보안 암호 삭제를 위한 aws cli
# aws secretsmanager delete-secret \
#   --secret-id "project/mysql/password" \
#   --force-delete-without-recovery
# ############################################################
resource "aws_secretsmanager_secret" "std11_db_password" {
  # std11-db-password 는 삭제 대기 중이라 같은 이름 재생성 불가
  name                    = "${local.tag_header}db-password-v2"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "std11_db_password_version" {
  secret_id = aws_secretsmanager_secret.std11_db_password.id
  secret_string = jsonencode({
    password = random_password.std11_db_password.result
    username = var.db_username
    database = "testdb"
    host     = aws_rds_cluster.std11_mysql_cluster.endpoint
  })
}

resource "random_password" "std11_db_password" {
  length           = 16
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
# ############################################################
# RDS Secrets Manager Automatic Rotation (00일 주기로 변경) - CloudFormation
# ############################################################
# 1. cloudformation의 스택을 배포하는 리소스 생성
resource "aws_serverlessapplicationrepository_cloudformation_stack" "std11_mysql_cluster" {
  name = "${local.tag_header}mysql-cluster"

  # 비밀번호 변경에 사용할 원본(기준) 함수의 arn 정의
  application_id = "arn:aws:serverlessrepo:us-east-1:297356227824:applications/SecretsManagerRDSMySQLRotationSingleUser"

  # CloudFormation이 iam 생성 및 리소스 정책을 정의할 수 있도록 승인하는 권한 설정
  capabilities = ["CAPABILITY_IAM", "CAPABILITY_RESOURCE_POLICY"]

  # lambda 함수 동작에 필요한 설정
  parameters = {
    # 람다함수 이름
    functionName = "std11_mysql_cluster_rotation"
    # 보안 암호의 endpoint 정의
    endpoint = "https://secretsmanager.${local.region}.amazonaws.com"

    #lambda 함수가 접속해야할 데이터베이스가 포함된 서브넷의 id 정의
    vpcSubnetIds        = join(",", [for s in aws_subnet.std11_private_subnet : s.id])
    vpcSecurityGroupIds = aws_security_group.std11_lambda_sg.id
  }

  tags = {
    Name = "${local.tag_header}mysql-cluster"
  }
}

resource "aws_secretsmanager_secret_rotation" "std11_db_password" {
  secret_id           = aws_secretsmanager_secret.std11_db_password.id
  rotation_lambda_arn = aws_serverlessapplicationrepository_cloudformation_stack.std11_mysql_cluster.outputs.RotationLambdaARN

  rotation_rules {
    automatically_after_days = 30
  }
}

# RDS MySQL 클러스터 생성
# ############################################################

# resource "aws_db_subnet_group" "std11_db_subnet_group" {
#   name       = "${local.tag_header}db-subnet-group"
#   subnet_ids = [for s in aws_subnet.std11_private_subnet : s.id]
#   tags = {
#     Name = "${local.tag_header}db-subnet-group"
#   }
# }


resource "aws_rds_cluster" "std11_mysql_cluster" {
  cluster_identifier = "${local.tag_header}mysql-cluster"
  engine             = "mysql"
  engine_version     = "8.0.46"

  db_cluster_instance_class = "db.m5d.large"

  # gp3 는 최소 3000 iops 이상 설정 필요
  storage_type      = "gp3"
  allocated_storage = 100
  # iops = 3000
  # throughput = 125

  database_name   = "testdb"
  master_username = var.db_username
  master_password = random_password.std11_db_password.result

  db_subnet_group_name   = aws_db_subnet_group.std11_db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.std11_mysql_sg.id]
  skip_final_snapshot    = true # 삭제 시 스냅샷 생성 여부

  # 수정할 때 볼륨으로 인한 에러 발생
  # 이에 최초 생성 이외 apply때 볼륨 변경을 무시하기 위한 설정
  lifecycle {
    ignore_changes = [
      storage_type,
      allocated_storage,
      iops,
    ]
  }
  tags = {
    Name = "${local.tag_header}mysql-cluster"
  }
}
