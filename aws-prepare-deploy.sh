#!/bin/bash
set -euo pipefail

# Simple helper to create ECR repo, ECS cluster and IAM execution role
# Usage: AWS_PROFILE=default ./aws-prepare-deploy.sh

REGION="us-east-1"
ECR_REPO="db-creation"
ECS_CLUSTER="db-creation-cluster"
EXEC_ROLE_NAME="ecsTaskExecutionRole-db-creation"
TASK_ROLE_NAME="ecsTaskRole-db-creation"

if [ ! -z "${AWS_REGION:-}" ]; then REGION="$AWS_REGION"; fi
if [ ! -z "${ECR_REPOSITORY:-}" ]; then ECR_REPO="$ECR_REPOSITORY"; fi
if [ ! -z "${ECS_CLUSTER_NAME:-}" ]; then ECS_CLUSTER="$ECS_CLUSTER_NAME"; fi

echo "Using region: $REGION"

echo "1/5 - Creating ECR repository (if not exists): $ECR_REPO"
aws ecr create-repository --repository-name "$ECR_REPO" --region "$REGION" 2>/dev/null || true

echo "2/5 - Creating ECS cluster: $ECS_CLUSTER"
aws ecs create-cluster --cluster-name "$ECS_CLUSTER" --region "$REGION" 2>/dev/null || true

echo "3/5 - Creating IAM task execution role: $EXEC_ROLE_NAME"
cat > /tmp/ecs-trust.json <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Service": "ecs-tasks.amazonaws.com" },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

aws iam create-role --role-name "$EXEC_ROLE_NAME" --assume-role-policy-document file:///tmp/ecs-trust.json 2>/dev/null || true
aws iam attach-role-policy --role-name "$EXEC_ROLE_NAME" --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy || true

echo "4/5 - (Optional) Creating a task role: $TASK_ROLE_NAME"
aws iam create-role --role-name "$TASK_ROLE_NAME" --assume-role-policy-document file:///tmp/ecs-trust.json 2>/dev/null || true

EXEC_ROLE_ARN=$(aws iam get-role --role-name "$EXEC_ROLE_NAME" --query 'Role.Arn' --output text)
TASK_ROLE_ARN=$(aws iam get-role --role-name "$TASK_ROLE_NAME" --query 'Role.Arn' --output text)

ECR_URI=$(aws ecr describe-repositories --repository-names "$ECR_REPO" --region "$REGION" --query 'repositories[0].repositoryUri' --output text)

echo "5/5 - Summary"
echo "ECR repository URI: $ECR_URI"
echo "ECS cluster name: $ECS_CLUSTER"
echo "Execution role ARN: $EXEC_ROLE_ARN"
echo "Task role ARN: $TASK_ROLE_ARN"

echo ""
echo "Next: set the following GitHub secrets for your repository (owner/repo):"
echo "  AWS_REGION=$REGION"
echo "  ECR_REPOSITORY=$ECR_REPO"
echo "  ECS_CLUSTER=$ECS_CLUSTER"
echo "  ECS_SERVICE=<your-ecs-service-name>  # create service in console or via CLI before running workflow"
echo "  CONTAINER_NAME=db-creation-container"
echo "  ECS_TASK_FAMILY=db-creation-task-family"
echo "  ECS_EXECUTION_ROLE_ARN=$EXEC_ROLE_ARN"
echo "  ECS_TASK_ROLE_ARN=$TASK_ROLE_ARN"

echo "If you have GitHub CLI installed you can run (replace OWNER/REPO):"
echo "  gh secret set AWS_REGION -b \"$REGION\" --repo OWNER/REPO"
echo "  gh secret set ECR_REPOSITORY -b \"$ECR_REPO\" --repo OWNER/REPO"
echo "  gh secret set ECS_CLUSTER -b \"$ECS_CLUSTER\" --repo OWNER/REPO"
echo "  gh secret set ECS_EXECUTION_ROLE_ARN -b \"$EXEC_ROLE_ARN\" --repo OWNER/REPO"
echo "  gh secret set ECS_TASK_ROLE_ARN -b \"$TASK_ROLE_ARN\" --repo OWNER/REPO"

echo "Create or configure an ECS Fargate service in the AWS Console and set the service name as the 'ECS_SERVICE' secret."
