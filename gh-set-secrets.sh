#!/bin/bash
set -euo pipefail

if [ $# -lt 2 ]; then
  echo "Usage: gh-set-secrets.sh OWNER/REPO AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY [AWS_REGION]"
  exit 1
fi

REPO="$1"
AWS_ACCESS_KEY_ID="$2"
AWS_SECRET_ACCESS_KEY="$3"
AWS_REGION="${4:-us-east-1}"

gh secret set AWS_ACCESS_KEY_ID --body "$AWS_ACCESS_KEY_ID" --repo "$REPO"
gh secret set AWS_SECRET_ACCESS_KEY --body "$AWS_SECRET_ACCESS_KEY" --repo "$REPO"
gh secret set AWS_REGION --body "$AWS_REGION" --repo "$REPO"

echo "Set base AWS secrets in $REPO. Now set the remaining secrets (ECR_REPOSITORY, ECS_CLUSTER, ECS_SERVICE, CONTAINER_NAME, ECS_TASK_FAMILY, ECS_EXECUTION_ROLE_ARN, ECS_TASK_ROLE_ARN) using the values provided by the aws-prepare-deploy.sh script."
