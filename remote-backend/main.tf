resource "aws_s3_bucket" "terraform-state" {
  bucket = "bipa17-std11-terraform-state-bucket"

  lifecycle {
    prevent_destroy = true # 버킷 삭제 방지
  }

  tags = {
    Name  = "std11-terraform-state-bucket" # 버킷 이름
    Class = "bipa17"
    Owner = "std11"
  }

}

# 상태 복구를 위한 버전 관리 활성화(상태 복구용)
resource "aws_s3_bucket_versioning" "state_versioning" {
  bucket = aws_s3_bucket.terraform-state.id
  versioning_configuration {
    status = "Enabled"
  }
}


# ##########################################################################################
# 2. 상태 잠금용 DynamoDB 테이블 생성
# ==========================================================================================

resource "aws_dynamodb_table" "terraform-lock" {
  name = "std11-terraform-state-lock"

  # dynamodb의 관리 방식 (비용과 연관된 설정)
  billing_mode = "PROVISIONED" # PAY_PER_REQUEST 대신 사용

  read_capacity  = 20 # 읽기 용량 단위 (초당 20회 4KB 단위) RCU(Read Capacity Unit) 1RCU = 1KB/s
  write_capacity = 20 # 쓰기 용량 단위 (초당 20회 4KB 단위) WCU(Write Capacity Unit) 1WCU = 1KB/s

  # 파티션 키. attribute 에 적은 이름은 여기(또는 range_key/GSI)에 안 쓰면 에러
  # Unused attributes: ["LockID"] = LockID 컬럼만 만들고 키로 안 씀
  hash_key = "LockID"

  attribute {
    name = "LockID" # 잠금 ID (테라폼 상태 잠금 관리를 위한 고유 키) 관계형 데이터베이스의 P/K같은 역할
    type = "S"      # 문자열 타입 (String), N(숫자), B(이진 데이터)
  }
}
