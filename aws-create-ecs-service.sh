#!/bin/bash
set -euo pipefail

usage(){
  cat <<EOF
Usage: AWS_PROFILE=... ./aws-create-ecs-service.sh \
  --cluster my-cluster \
  --service my-service \
  --task-family db-creation-task-family \
  --container-name db-creation-container \
  --subnets subnet-aaa,subnet-bbb \
  --security-groups sg-aaa \
  [--region us-east-1]

This script will:
 - create a Target Group
 - create an Internet-facing Application Load Balancer
 - create a Listener on port 80
 - create an ECS Fargate service that uses the ALB

You must already have a registered task definition family (workflow will create new revisions).
EOF
  exit 1
}

ARGS=$(getopt -o '' -l cluster:,service:,task-family:,container-name:,subnets:,security-groups:,region: -n "aws-create-ecs-service.sh" -- "$@")
if [ $? -ne 0 ]; then usage; fi
eval set -- "$ARGS"

while true; do
  case "$1" in
    --cluster) CLUSTER="$2"; shift 2;;
    --service) SERVICE="$2"; shift 2;;
    --task-family) TASK_FAMILY="$2"; shift 2;;
    --container-name) CONTAINER_NAME="$2"; shift 2;;
    --subnets) SUBNETS_CSV="$2"; shift 2;;
    --security-groups) SECURITY_GROUPS="$2"; shift 2;;
    --region) REGION="$2"; shift 2;;
    --) shift; break;;
  esac
done

: "${REGION:=us-east-1}"

if [ -z "${CLUSTER:-}" ] || [ -z "${SERVICE:-}" ] || [ -z "${TASK_FAMILY:-}" ] || [ -z "${CONTAINER_NAME:-}" ] || [ -z "${SUBNETS_CSV:-}" ] || [ -z "${SECURITY_GROUPS:-}" ]; then
  usage
fi

IFS=',' read -r -a SUBNETS <<< "$SUBNETS_CSV"

echo "Using region: $REGION"

# Get vpc id from first subnet
VPC_ID=$(aws ec2 describe-subnets --subnet-ids ${SUBNETS[0]} --region $REGION --query 'Subnets[0].VpcId' --output text)
echo "Detected VPC: $VPC_ID"

TG_NAME="${SERVICE}-tg"
ALB_NAME="${SERVICE}-alb"

echo "Creating target group: $TG_NAME"
TG_ARN=$(aws elbv2 create-target-group --name "$TG_NAME" --protocol HTTP --port 8000 --vpc-id $VPC_ID --target-type ip --health-check-protocol HTTP --health-check-path /docs --health-check-interval-seconds 30 --region $REGION --query 'TargetGroups[0].TargetGroupArn' --output text)
echo "Target group ARN: $TG_ARN"

echo "Creating load balancer: $ALB_NAME"
ALB_JSON=$(aws elbv2 create-load-balancer --name "$ALB_NAME" --subnets ${SUBNETS_CSV//,/ } --security-groups $SECURITY_GROUPS --scheme internet-facing --type application --region $REGION)
ALB_ARN=$(echo "$ALB_JSON" | jq -r '.LoadBalancers[0].LoadBalancerArn')
ALB_DNS=$(echo "$ALB_JSON" | jq -r '.LoadBalancers[0].DNSName')

echo "ALB ARN: $ALB_ARN"
echo "ALB DNS: $ALB_DNS"

echo "Creating listener on port 80 forwarding to target group"
aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN --region $REGION >/dev/null

echo "Creating ECS service: $SERVICE"

# Create service (if exists, update will be needed)
aws ecs create-service \
  --cluster "$CLUSTER" \
  --service-name "$SERVICE" \
  --task-definition "$TASK_FAMILY" \
  --launch-type FARGATE \
  --desired-count 1 \
  --network-configuration "awsvpcConfiguration={subnets=[${SUBNETS_CSV}],securityGroups=[${SECURITY_GROUPS}],assignPublicIp=ENABLED}" \
  --load-balancers "targetGroupArn=$TG_ARN,containerName=$CONTAINER_NAME,containerPort=8000" \
  --region $REGION || true

echo "Service created or already exists. ALB DNS: $ALB_DNS"
echo "If tasks don't start, check the ECS service events and task definitions."
