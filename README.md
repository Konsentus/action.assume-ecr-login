# Run e2e Tests

This action will login to an AWS ECR repository, pull down a docker image which runs the tests and then
runs the image.

## Usage

### Example Pipeline

```yaml
name: Run e2e tests
on:
  push:
    branches:
      - "master"
jobs:
  run-e2e-test:
    env:
      AWS_REGION: eu-west-2
      AWS_ACCOUNT_ROLE: deploy
      AWS_ACCOUNT_ID: ${{ secrets.ECR_AWS_ACCOUNT_ID }}
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    name: Download and run test runner
    runs-on: ubuntu-latest
    steps:
      - name: Download
        uses: konsentus/action.run-e2e-tests@master
        with:
          environment: pre-prod
          image: postman/newman
```

## Environment Variables

- `AWS_REGION`: The region in which the ECR repository exists.
- `AWS_ACCOUNT_ROLE`: The name of a IAM Role that has the [required permissions](#Role-permissions) to push to the AWS ECR repository.
- `AWS_ACCOUNT_ID`: The account number of the AWS account in which the ECR repository exists.
- `AWS_ACCESS_KEY_ID`: The AWS Access Key ID of a user with permission to assume the **AWS_ACCOUNT_ROLE**.
- `AWS_SECRET_ACCESS_KEY`: The AWS Secret Access Key that pairs with the `AWS_ACCESS_KEY_ID`.

## Input Parameters

- `environment` : The environment which the tests are to be run against.
- `image` : The image which contains the tests and test runner.

**Suggestion**: Store your AWS account details in [Secrets](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/creating-and-using-encrypted-secrets)

## Role permissions

This action uses [AWS Security Token Service](https://docs.aws.amazon.com/STS/latest/APIReference/Welcome.html) to assume the **AWS_ACCOUNT_ROLE**.

The following shows an example policy containing the permissions that are required for the **AWS_ACCOUNT_ROLE** to perform the AWS commands contained in the action.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:ListImages",
        "ecr:DescribeImages",
        "ecr:TagResource",
        "ecr:PutImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```
