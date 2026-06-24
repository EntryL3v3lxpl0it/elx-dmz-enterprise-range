# ---------------------------------------------------------------------------
# Bootstrap stack: creates the encrypted, versioned S3 bucket used as the
# Terraform remote state backend for the team environments.
#
# This stack uses LOCAL state (no backend block) to avoid the chicken-and-egg
# problem of needing a bucket to store the state that creates the bucket.
# Run this ONCE per account, then configure envs/team1 to use the bucket.
# ---------------------------------------------------------------------------

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "elx-dmz-enterprise-range"
      Environment = "shared"
      Owner       = var.owner
      CostControl = "true"
      ManagedBy   = "terraform"
      Component   = "tf-state-backend"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  bucket_name = coalesce(
    var.state_bucket_name,
    "elx-tfstate-${data.aws_caller_identity.current.account_id}-${var.aws_region}"
  )
}

resource "aws_s3_bucket" "tfstate" {
  bucket = local.bucket_name

  # Safety: prevent accidental destruction of the state bucket.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  rule {
    apply_server_side_encryption_by_default {
      # SSE-S3 (AES256) — no KMS key cost. Switch to aws:kms if a CMK is required.
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket                  = aws_s3_bucket.tfstate.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce TLS-only access to the state bucket.
resource "aws_s3_bucket_policy" "tfstate_tls_only" {
  bucket = aws_s3_bucket.tfstate.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.tfstate.arn,
          "${aws_s3_bucket.tfstate.arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}
