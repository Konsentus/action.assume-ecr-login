#!/bin/bash -l

## Standard ENV variables provided
# ---
# GITHUB_ACTION=The name of the action
# GITHUB_ACTOR=The name of the person or app that initiated the workflow
# GITHUB_EVENT_PATH=The path of the file with the complete webhook event payload.
# GITHUB_EVENT_NAME=The name of the event that triggered the workflow
# GITHUB_REPOSITORY=The owner/repository name
# GITHUB_BASE_REF=The branch of the base repository (eg the destination branch name for a PR)
# GITHUB_HEAD_REF=The branch of the head repository (eg the source branch name for a PR)
# GITHUB_REF=The branch or tag ref that triggered the workflow
# GITHUB_SHA=The commit SHA that triggered the workflow
# GITHUB_WORKFLOW=The name of the workflow that triggerdd the action
# GITHUB_WORKSPACE=The GitHub workspace directory path. The workspace directory contains a subdirectory with a copy of your repository if your workflow uses the actions/checkout action. If you don't use the actions/checkout action, the directory will be empty

# for logging and returning data back to the workflow,
# see https://help.github.com/en/articles/development-tools-for-github-actions#logging-commands
# echo ::set-output name={name}::{value}
# -- DONT FORGET TO SET OUTPUTS IN action.yml IF RETURNING OUTPUTS

# Ensures required environment variables are supplied by workflow
check_env_vars() {
  local requiredVariables=(
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "AWS_ACCOUNT_ROLE"
    "AWS_ACCOUNT_ID"
    "AWS_REGION"
  )

  for VARIABLE_NAME in "${requiredVariables[@]}"
  do
    if [[ -z "${!VARIABLE_NAME}" ]]; then
      echo "Required environment variable: ${VARIABLE_NAME} is not defined" >&2
      return 3
    fi
  done
}

# Assume a role in AWS using AWS STS
assume_role() {
  echo "Assuming role: ${AWS_ACCOUNT_ROLE} in account: ${AWS_ACCOUNT_ID}"

  local credentials

  credentials=$(aws sts assume-role --role-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:role/${AWS_ACCOUNT_ROLE}" --role-session-name docker-build-and-push --output json)

  if [ $? -ne 0 ]; then
    echo "Failed to assume role ${AWS_ACCOUNT_ROLE} in account: ${AWS_ACCOUNT_ID}" >&2
    return 3
  fi

  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_SESSION_TOKEN
  export AWS_DEFAULT_REGION=${AWS_REGION}

  AWS_ACCESS_KEY_ID=$(jq -r .Credentials.AccessKeyId <<< ${credentials})
  AWS_SECRET_ACCESS_KEY=$(jq -r .Credentials.SecretAccessKey <<< ${credentials})
  AWS_SESSION_TOKEN=$(jq -r .Credentials.SessionToken <<< ${credentials})

  echo "Successfully assumed role"
}

# Request ECR credentials and execute returned command to login
login_to_ecr() {
  echo "Logging into ECR in region: ${AWS_REGION}"
  $(aws ecr get-login --no-include-email --region ${AWS_REGION})

  if [ $? -ne 0 ]; then
    echo "Failed to log into AWS ECR" >&2
    return 3
  fi

  echo "Successfully logged into ECR"
}

check_env_vars || exit $?

# Assume role with permission to login to ECR
assume_role || exit $?

# Execute inline login to AWS ECR
login_to_ecr || exit $?

# Execute e2e test
docker run -e COLLECTION_TYPE=public -e ENVIRONMENT=${INPUT_ENVIRONMENT} -e REPORT_DIR=/report \
  --rm -v `pwd`/report:/report ${INPUT_IMAGE}:${INPUT_ENVIRONMENT}

docker_result=$?
if [ $docker_result -ne 0 ]; then
  echo "Docker returned exit code $docker_result"
  exit($docker_result);
fi

echo "Successfully run tests, setting report as output"

cat report/public-${INPUT_ENVIRONMENT}.html

echo ::set-output name=report::`cat report/public-${INPUT_ENVIRONMENT}.html`