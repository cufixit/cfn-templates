include ./makefile.env

STACK_NAME=cu-fixit

.PHONY: package
package: packaged.yaml
packaged.yaml: main.yaml api.yaml lambda.yaml
	aws cloudformation package --template-file main.yaml --output-template packaged.yaml --s3-bucket $(CFN_TEMPLATE_SOURCE_BUCKET)

.PHONY: deploy
deploy: packaged.yaml
	aws cloudformation deploy --template-file packaged.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides LambdaCodeSourceBucket=$(LAMBDA_CODE_SOURCE_BUCKET) CognitoUserPoolArn=$(COGNITO_USER_POOL_ARN) CognitoAdminPoolArn=$(COGNITO_ADMIN_POOL_ARN)

.PHONY: deploy-api
deploy-api: deploy
	$(eval API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`ApiId`].OutputValue' --output text --no-paginate))
	aws apigateway create-deployment --rest-api-id $(API_ID) --stage-name dev