###############################################################################
# Random suffix — bucket names are globally unique across all of AWS
###############################################################################

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

###############################################################################
# S3 bucket for honeypot log ingestion
###############################################################################

resource "aws_s3_bucket" "honeypot_logs" {
  bucket = "${var.project_name}-honeypot-logs-${random_id.bucket_suffix.hex}"

  tags = {
    Name    = "${var.project_name}-honeypot-logs"
    Purpose = "honeypot-log-ingestion"
  }
}

# Block all public access (defense in depth — AWS Block Public Access)
resource "aws_s3_bucket_public_access_block" "honeypot_logs" {
  bucket = aws_s3_bucket.honeypot_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Versioning — required to recover from accidental or malicious deletes
resource "aws_s3_bucket_versioning" "honeypot_logs" {
  bucket = aws_s3_bucket.honeypot_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption with AES-256 (AWS-managed keys, no KMS cost)
resource "aws_s3_bucket_server_side_encryption_configuration" "honeypot_logs" {
  bucket = aws_s3_bucket.honeypot_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Lifecycle — transition current objects to Glacier after 90 days;
# expire old non-current versions after 1 year to control cost
resource "aws_s3_bucket_lifecycle_configuration" "honeypot_logs" {
  bucket = aws_s3_bucket.honeypot_logs.id

  depends_on = [aws_s3_bucket_versioning.honeypot_logs]

  rule {
    id     = "archive-old-logs"
    status = "Enabled"

    filter {}

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}
