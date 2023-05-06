include ./.env
include ./makefile.env

STACK_NAME=cu-fixit
STACKS := $(shell find stacks -type f -name "*.yaml")

.PHONY: package
package: packaged.yaml
packaged.yaml: root.yaml $(STACKS)
	aws cloudformation package --template-file root.yaml --output-template packaged.yaml --s3-bucket $(CFN_TEMPLATE_SOURCE_BUCKET)

.PHONY: deploy
deploy: packaged.yaml
	aws cloudformation deploy --template-file packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides LambdaCodeSourceBucket=$(LAMBDA_CODE_SOURCE_BUCKET) CognitoUserPoolId=$(COGNITO_USER_POOL_ID) CognitoAdminPoolId=$(COGNITO_ADMIN_POOL_ID) \
	OpenSearchMasterUserName=$(OPENSEARCH_MASTER_USER_NAME) OpenSearchMasterUserPassword=$(OPENSEARCH_MASTER_USER_PASSWORD)

.PHONY: user-api
user-api:
	$(eval USER_API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`UserApiId`].OutputValue' --output text --no-paginate))
	aws apigateway create-deployment --rest-api-id $(USER_API_ID) --stage-name dev --output text

.PHONY: admin-api
admin-api:
	$(eval ADMIN_API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`AdminApiId`].OutputValue' --output text --no-paginate))
	aws apigateway create-deployment --rest-api-id $(ADMIN_API_ID) --stage-name dev --output text

.PHONY: all
all: package deploy user-api admin-api

.PHONY: clean
clean:
	rm -f packaged.yaml