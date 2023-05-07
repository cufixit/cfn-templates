# CloudFormation Templates

This repository contains the CloudFormation templates for the `cu-fixit` stack. All resources and configurations are deployed through CloudFormation with the following exceptions:

- S3 bucket storing Lambda deployment packages
- S3 bucket storing packaged CloudFormation templates for nested stacks
- Cognito user pools for users and admin

Note: All OpenSearch configurations are made through custom resources, including index mappings and role mappings.

The S3 buckets and Cognito user pools need to be created before the stack is deployed. These resources are specified in `makefile.env`.

## Quick Start

To get started, update `makefile.env` if needed. Also create a `.env` file in the root directory with the following secrets:

```
OPENSEARCH_MASTER_USER_NAME=
OPENSEARCH_MASTER_USER_PASSWORD=
```

Run `make package` to package the CloudFormation templates.

Run `make deploy` to deploy the entire CloudFormation stack. Before deploying, it is good to make sure that all of the Lambda deployment packages needed have been uploaded to the code source S3 bucket specified in `makefile.env`.

Run `make user-api` to create a new API Gateway deployment for the user API.

Run `make admin-api` to create a new API Gateway deployment for the admin API.
