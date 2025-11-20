variable "project_name" {
  description = "Project Name"
  type        = string
}
variable "tags" {
  description = "Base tags applied to security resources"
  type        = map(string)
  default     = {}
}
variable "cloudtrail_force_destroy" {
  description = "Whether to allow terraform to delete CloudTrail S3 bucket"
  type        = bool
  default     = false
}
variable "enable_guardduty" {
  description = "Whether to enable GuardDuty in this account/region"
  type        = bool
  default     = false
}
