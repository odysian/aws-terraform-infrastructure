data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  cloudtrail_bucket_name = "cloudtrail-logs-${var.project_name}-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = local.cloudtrail_bucket_name
  force_destroy = var.cloudtrail_force_destroy

  tags = {
    Name = "cloudtrail-logs-${var.project_name}"
  }
}

# Block all public access to CloudTrail log bucket
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable default server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Allow Cloudtrail to write logs into this bucket
resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = aws_s3_bucket.cloudtrail_logs.arn
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}


# Multi region CloudTrail for the account, logging to the bucket above
resource "aws_cloudtrail" "this" {
  name                          = "account-trail-${var.project_name}"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  # Ensure bucket + policy exist before trail creation  
  depends_on = [
    aws_s3_bucket_policy.cloudtrail_logs
  ]

  tags = {
    Name = "account-trail-${var.project_name}"
  }
}

# Enable GuardDuty in this account/region
resource "aws_guardduty_detector" "this" {
  count = var.enable_guardduty ? 1 : 0

  enable = true

  # Fast publishing interval
  finding_publishing_frequency = "FIFTEEN_MINUTES"

  tags = {
    Name = "guardduty-${var.project_name}"
  }
}
