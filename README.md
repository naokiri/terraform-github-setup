# About
Base backend infrastructure to run my terraform deployment on github.
As this is a personal stuff, all deployments are done by one role created in this terraform file.

## Not automated stuffs
### AWS
- Have to prepare the Role (assume_role_arn) to assume for running this terraform file manually. Requires heavy iam and s3 (and possibly dynamodb in the future?) permissions.
- Have to prepare the Policy (terraform_operation_policy_arn) that does perform deployments to be attached to the GithubRole

### Azure
- Unlike AWS, this doesn't create a service principal for deployment. Each project have to prepare and use own active directory application and setup the federation.

## Description
This repo's resources' tfstate is not controlled by the cloud backend itself. So don't forget to run 

    terraform import RESOURCE_NAME ID
    e.g. terraform import aws_s3_bucket_server_side_encryption_configuration.infra_encryption my.infra 
    
for each of the resources before running terraform plan & apply in a new env.
