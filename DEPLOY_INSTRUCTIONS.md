# Deploy pipeline — instructions

1) Prerequisites
- AWS CLI configured locally with permissions to create ECR, ECS, and IAM resources.
- `gh` (GitHub CLI) optional to set repo secrets from terminal.

2) Run the prepare script on a machine with AWS CLI credentials:

```bash
chmod +x aws-prepare-deploy.sh
./aws-prepare-deploy.sh
```

This will create an ECR repository, an ECS cluster, and two IAM roles (execution and task). The script prints the ARNs and the ECR URI.

3) Add GitHub Secrets (Repository → Settings → Secrets → Actions)
- `AWS_ACCESS_KEY_ID` — your AWS access key
- `AWS_SECRET_ACCESS_KEY` — your AWS secret key
- `AWS_REGION` — same region used above (e.g., `us-east-1`)
- `ECR_REPOSITORY` — (from script or your choice)
- `ECS_CLUSTER` — (created by the script or your chosen name)
- `ECS_SERVICE` — create an ECS service in console or via CLI; set its name here
- `CONTAINER_NAME` — name used inside task (e.g., `db-creation-container`)
- `ECS_TASK_FAMILY` — task family name (e.g., `db-creation-task-family`)
- `ECS_EXECUTION_ROLE_ARN` — from script output
- `ECS_TASK_ROLE_ARN` — from script output

You can set secrets using `gh`:

```bash
gh secret set AWS_ACCESS_KEY_ID --body "<key>" --repo OWNER/REPO
gh secret set AWS_SECRET_ACCESS_KEY --body "<secret>" --repo OWNER/REPO
# ...repeat for each secret
```

4) Ensure the ECS service exists

Create a Fargate service (1 task) that uses the same VPC/subnets as your cluster and allows inbound traffic to the target port (8000) via a load balancer or public IP. You can create a placeholder task/service in the console; the GitHub Actions workflow will register a new task definition and force a new deployment.

5) Trigger the workflow

Push to `master` (already pushed). After secrets are configured, the workflow will:
- Build and push the Docker image to ECR
- Register a task definition
- Force update the ECS service to use the new task definition

6) Verify

- In the AWS ECS Console → Clusters → Services, check the service events and task status
- Check the application endpoint (load balancer DNS or public IP/port)

If you want, I can generate the exact `aws` CLI commands to create the ECS service and load balancer for you — tell me your VPC/subnet IDs or allow me to detect them from your default VPC.
