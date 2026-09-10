# provider.tf 파일명의 경우 아무렇게나 주어도 되지만 무엇을 쓸 지 알아야 함.
# 예를 들어, provider.tf 파일명의 경우 아무렇게나 주어도 되지만 무엇을 쓸 지 알아야 함.
# provider.tf : 클라우드 공급자(aws/gcp), 버전, 리전 생성
# variables.tf : 환경변수 정의
# terraform.tfvars : 환경변수 값 설정
# local.tf : 로컬 변수 설정
# data.tf : 기존 리소스 정의(조회)
# output.tf : 출력 결과 및 모듈로 기존 리소스 연결
# main.tf : 리소스 정의 및 모듈 호출

# ##########################################################################################
# 1. 테라폼 실행 환경 설정 블록
# ==========================================================================================
terraform {
  required_providers {
    aws = {
      # 프로바이더 라이브러리 다운로드 경로
      source = "hashicorp/aws"
      # 사용할 버전 정의
      version = "~> 6.0" # 5.0 이상 5.x.x 버전 사용
      # 리전 정의
      #   region = "eu-central-1"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
  # 창고(버킷)는 remote-backend 에서 만든 거 그대로 공유
  # key 만 network 전용. 여기랑 remote-backend key 가 같으면 장부가 섞임
  backend "s3" {
    bucket         = "bipa17-std11-terraform-state-bucket"
    key            = "TerraformState/Lab/module/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "std11-terraform-state-lock"
    encrypt        = true
  }
}
provider "aws" {
  region = "eu-central-1"
  default_tags { # 기본 태그 설정
    tags = {
      Class = "bipa17"
      Owner = "std11"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
  alias  = "std11"
  default_tags {
    tags = {
      Class = "bipa17"
      Owner = "std11"
    }
  }
}
