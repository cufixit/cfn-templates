include ./.env
include ./makefile.env

STACK_NAME=cu-fixit

.PHONY: package
package: packaged.yaml
packaged.yaml: main.yaml lambda.yaml api-user.yaml api-admin.yaml
	aws cloudformation package --template-file main.yaml --output-template packaged.yaml --s3-bucket $(CFN_TEMPLATE_SOURCE_BUCKET)

.PHONY: deploy
deploy: packaged.yaml
	aws cloudformation deploy --template-file packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides LambdaCodeSourceBucket=$(LAMBDA_CODE_SOURCE_BUCKET) CognitoUserPoolArn=$(COGNITO_USER_POOL_ARN) CognitoAdminPoolArn=$(COGNITO_ADMIN_POOL_ARN) \
	ReportsDomainMasterUserName=$(REPORTS_DOMAIN_MASTER_USER_NAME) ReportsDomainMasterUserPassword=$(REPORTS_DOMAIN_MASTER_USER_PASSWORD)

.PHONY: deploy-api
deploy-api: deploy
	$(eval USER_API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`UserApiId`].OutputValue' --output text --no-paginate))
	$(eval ADMIN_API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`AdminApiId`].OutputValue' --output text --no-paginate))
	aws apigateway create-deployment --rest-api-id $(USER_API_ID) --stage-name dev --output text
	aws apigateway create-deployment --rest-api-id $(ADMIN_API_ID) --stage-name dev --output text