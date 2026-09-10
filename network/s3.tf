# s3.tf
# #########################################################################
# 정적 웹용 버킷. 이름은 전 세계 유일
# #########################################################################

resource "aws_s3_bucket" "std11_ex_bucket" {
  bucket              = "bipa17-std11-ex-bucket"
  force_destroy       = false
  object_lock_enabled = false

  tags = {
    Name = "bipa17-std11-ex-bucket"
  }
}

resource "aws_s3_bucket_versioning" "std11_ex_bucket_versioning" {
  bucket = aws_s3_bucket.std11_ex_bucket.id

  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "std11_ex_bucket_access" {
  bucket = aws_s3_bucket.std11_ex_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "std11_ex_bucket_website" {
  bucket = aws_s3_bucket.std11_ex_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

resource "aws_s3_bucket_policy" "std11_ex_bucket_policy" {
  bucket = aws_s3_bucket.std11_ex_bucket.id

  depends_on = [
    aws_s3_bucket_public_access_block.std11_ex_bucket_access
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.std11_ex_bucket.arn}/*"
      }
    ]
  })
}

output "std11_ex_bucket_website_endpoint" {
  value = aws_s3_bucket_website_configuration.std11_ex_bucket_website.website_endpoint
}
