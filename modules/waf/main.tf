resource "aws_wafv2_web_acl" "this" {
  name        = "${var.project_name}-web-acl"
  description = "Basic WAF for ${var.project_name} ALB"
  scope       = "REGIONAL" # for ALB / API Gateway / AppSync

  default_action {
    allow {}
  }

  # Baseline protection: AWS managed rule groups
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}_waf_common"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}_waf_bad_inputs"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 3

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    override_action {
      none {}
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project_name}_waf_sqli"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project_name}_waf"
    sampled_requests_enabled   = true
  }

  tags = {
    Name    = "${var.project_name}-web-acl"
    Project = var.project_name
  }
}

# Attach WAF Web ACL to the ALB
resource "aws_wafv2_web_acl_association" "alb" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.this.arn
}
