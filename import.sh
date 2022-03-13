#!/bin/bash
set -eux
BUCKET_NAME=my.infra
OIDC_ARN="arn:aws:iam::THENUMBER:oidc-provider/token.actions.githubusercontent.com"

terraform import aws_s3_bucket.infra $BUCKET_NAME
terraform import aws_s3_bucket_versioning.infra_versioning $BUCKET_NAME
terraform import aws_s3_bucket_server_side_encryption_configuration.infra_encryption $BUCKET_NAME
terraform import aws_iam_openid_connect_provider.github_oidc $OIDC_ARN
terraform import aws_iam_role.github_role GithubRole
