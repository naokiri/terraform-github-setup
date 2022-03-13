# About
Base backend infrastructure to run my terraform deployment on github.

## Prerequiste

- Have to prepare the Role to assume for running terraform manually (TODO: Separate this bootstrapping role and the actual assumed role on other deployments)

## Description
This repo's resources' tfstate is not controlled by the cloud backend itself. So don't forget to run 

    terraform import RESOURCE_NAME ID
    e.g. terraform import aws_s3_bucket_server_side_encryption_configuration.infra_encryption my.infra 
    
for each of the resources before running terraform plan & apply in a new env.
