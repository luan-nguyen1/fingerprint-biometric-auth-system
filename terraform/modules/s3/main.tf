resource "random_id" "bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "fingerprint_bucket" {
  bucket        = "fingerprint-reference-${random_id.bucket_suffix.hex}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "public_block" {
  bucket = aws_s3_bucket.fingerprint_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

output "bucket_name" {
  value = aws_s3_bucket.fingerprint_bucket.bucket
}
