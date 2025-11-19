data "aws_caller_identity" "current" {}

data "aws_elb_service_account" "this" {}

# Bucket policy
data "aws_iam_policy_document" "alb_logs" {
  # ALB log delivery needs to read the bucket ACL
  statement {
    sid     = "AWSALBLogDeliveryAclCheck"
    effect  = "Allow"
    actions = ["s3:GetBucketAcl"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    resources = [
      aws_s3_bucket.alb_logs.arn
    ]
  }


  statement {
    sid     = "AWSALBLogDeliveryWrite"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    resources = [
      "${aws_s3_bucket.alb_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
    ]
  }
}

# ALB S3 Log Bucket
resource "aws_s3_bucket" "alb_logs" {
  bucket = "${var.project_name}-alb-logs-terraform-odys"
  tags = {
    Name    = "${var.project_name}-alb-logs"
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  rule {
    id     = "expire-alb-logs-after-30-days"
    status = "Enabled"

    filter {
      prefix = "" # All objects
    }

    expiration {
      days = 30
    }
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Allow the ALB log delivery service to write logs into this bucket
resource "aws_s3_bucket_policy" "alb_logs" {
  bucket = aws_s3_bucket.alb_logs.id

  policy = data.aws_iam_policy_document.alb_logs.json
}
