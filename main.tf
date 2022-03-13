terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.5.0"
    }
    tls = {
      source = "hashicorp/tls"
      version = "~> 3.1.0"
    }
  }

  required_version = ">= 0.14.9"
}

variable "private" {
  description = "Just hidden not to expose on public repo"
  type =object({
    assume_role_arn = string
    infra_bucket_name = string
  })
}

provider "aws" {
  profile = "default"
  region  = "ap-northeast-1"
  assume_role {
    role_arn = var.private.assume_role_arn
  }
}

data "tls_certificate" "oidc_certificate" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github_oidc" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list =[data.tls_certificate.oidc_certificate.certificates[0].sha1_fingerprint]
}

resource "aws_s3_bucket" "infra" {
  bucket = var.private.infra_bucket_name

  tags = {
    Env = "Prod"
  }
}

resource "aws_s3_bucket_versioning" "infra_versioning" {
  bucket = aws_s3_bucket.infra.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "infra_encryption" {
  bucket = aws_s3_bucket.infra.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}
