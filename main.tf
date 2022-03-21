terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 3.1.0"
    }
  }

  required_version = ">= 0.14.9"
}

variable "private" {
  description = "Just hidden not to expose on public repo"
  type        = object({
    account                        = string
    assume_role_arn                = string
    infra_bucket_name              = string
    # Strings like "repo:naokiri/reponame:*"
    # See https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect#example-subject-claims
    allowed_subs                   = list(string)
    terraform_operation_policy_arn = list(string)
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
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_certificate.certificates[0].sha1_fingerprint]
}

resource "aws_iam_role" "github_role" {
  name               = "GithubRole"
  description        = "Role to assume from github"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : aws_iam_openid_connect_provider.github_oidc.arn
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "token.actions.githubusercontent.com:aud" : "sts.amazonaws.com"
          }
          "StringLike" : {
            "token.actions.githubusercontent.com:sub" : var.private.allowed_subs
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "assume_terraform_github_deploy" {
  name   = "AssumeGithubTerraformApplyRole"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Resource" : aws_iam_role.terraform_github_apply_role.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attatch_assume_github_terraform" {
  role       = aws_iam_role.github_role.id
  policy_arn = aws_iam_policy.assume_terraform_github_deploy.id
}

resource "aws_iam_role" "terraform_github_apply_role" {
  name                = "TerraformGithubApplyRole"
  description         = "Role to assume in github managed terraform files"
  managed_policy_arns = var.private.terraform_operation_policy_arn
  assume_role_policy  = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      # Principal to apply from local cli
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : format("arn:aws:iam::%s:user/cli", var.private.account)
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {}
      },
      # Principal to be used from github role
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : aws_iam_role.github_role.arn
        },
        "Action" : "sts:AssumeRole",
        "Condition" : {}
      }
    ]
  })
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

resource "aws_s3_bucket_public_access_block" "infra_public_access" {
  bucket = aws_s3_bucket.infra.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "infra_encryption" {
  bucket = aws_s3_bucket.infra.id
  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
