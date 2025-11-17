terraform {
  backend "s3" {
    bucket         = "odys-terraform-state-2025"
    key            = "aws-terraform-infrastructure/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-locks"
  }
}
