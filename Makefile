include ./.env
include ./makefile.env

.DEFAULT_GOAL := help
STACK_NAME=cu-fixit
STACKS := $(shell find stacks -type f -name "*.yaml")

.PHONY: help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONY: package
package: packaged.yaml
packaged.yaml: root.yaml $(STACKS) ## package all CloudFormation templates
	aws cloudformation package --template-file root.yaml --output-template packaged.yaml --s3-bucket $(CFN_TEMPLATE_SOURCE_BUCKET)

.PHONY: deploy
deploy: packaged.yaml ## deploy all CloudFormation templates to AWS
	aws cloudformation deploy --template-file packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides LambdaCodeSourceBucket=$(LAMBDA_CODE_SOURCE_BUCKET) CognitoUserPoolId=$(COGNITO_USER_POOL_ID) CognitoAdminPoolId=$(COGNITO_ADMIN_POOL_ID) \
	OpenSearchMasterUserName=$(OPENSEARCH_MASTER_USER_NAME) OpenSearchMasterUserPassword=$(OPENSEARCH_MASTER_USER_PASSWORD)

.PHONY: user-api
user-api: ## create a new API Gateway deployment for the user API
	$(eval USER_API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`UserApiId`].OutputValue' --output text --no-paginate))
	aws apigateway create-deployment --rest-api-id $(USER_API_ID) --stage-name dev --output text

.PHONY: admin-api
admin-api: ## create a new API Gateway deployment for the admin API
	$(eval ADMIN_API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`AdminApiId`].OutputValue' --output text --no-paginate))
	aws apigateway create-deployment --rest-api-id $(ADMIN_API_ID) --stage-name dev --output text

.PHONY: all
all: package deploy user-api admin-api ## package and deploy all CloudFormation templates to AWS

.PHONY: clean
clean: ## remove all build artifacts
	rm -f packaged.yaml