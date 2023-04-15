include ./makefile.env

STACK_NAME=cu-fixit-api

.PHONY: api-stack
api-stack: apigateway.yaml
	aws cloudformation deploy --template-file apigateway.yaml --stack-name $(STACK_NAME) --capabilities CAPABILITY_IAM \
	--parameter-overrides CognitoUserPoolArn=$(COGNITO_USER_POOL_ARN) CognitoAdminPoolArn=$(COGNITO_ADMIN_POOL_ARN)

.PHONY: api
api: api-stack
	$(eval API_ID := $(shell aws cloudformation describe-stacks --stack-name $(STACK_NAME) --query 'Stacks[0].Outputs[?OutputKey==`ApiId`].OutputValue' --output text --no-paginate))
	aws apigateway create-deployment --rest-api-id $(API_ID) --stage-name dev