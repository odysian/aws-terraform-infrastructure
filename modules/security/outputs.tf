output "cloudtrail_bucket_name" {
  description = "Name of the S3 bucket storing CloudTrail Logs"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

output "cloudtrail_trail_arn" {
  description = "ARN of the CloudTrail trail"
  value       = aws_cloudtrail.this.arn
}

output "guardduty_detector_id" {
  description = "ID of the GuardDuty detector"
  value       = length(aws_guardduty_detector.this) > 0 ? aws_guardduty_detector.this[0].id : null
}
