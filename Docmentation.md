# Damolak Web App — DevOps Practical Challenge

A production-ready Next.js application deployed on **AWS ECS Fargate** with full CI/CD automation via **GitHub Actions** and infrastructure managed with **Terraform** (local state).

---

## Architecture Overview

```
Internet
    │
    ▼
┌─────────────────────────────────┐
│  Application Load Balancer      │  (internet-facing, HTTP:80)
│  Security Group: dev-alb-sg     │
│  Public Subnets (2x AZs)        │
└────────────┬────────────────────┘
             │  Listener Rule → /*
             ▼
┌─────────────────────────────────┐
│  ALB Target Group               │  Health check: GET /api/health
│  dev-web-app-tg                 │
└────────────┬────────────────────┘
             │
             ▼
┌─────────────────────────────────┐
│  ECS Fargate Task               │  Port 3000
│  Next.js 15 (standalone)        │
│  Private Subnet (no public IP)  │
│  Security Group: dev-web-app-sg │
│   → inbound from ALB SG only    │
└──────────┬──────────────────────┘
           │ outbound via NAT Gateway
     ┌─────┴─────────┐
     ▼               ▼
┌──────────┐  ┌──────────────────┐
│CloudWatch│  │  Secrets Manager │
│Log Group │  │  API_BASE_URL    │
└──────────┘  └──────────────────┘
```

### Infrastructure Layers

```
infra/
├── shared/    VPC · public subnets · private subnets · IGW · NAT Gateway
├── platform/  ECR repo · IAM roles · ECS cluster · ALB · ALB listeners
└── web-app/   ECS task · ECS service · target group · listener rule
               CloudWatch log group · Secrets Manager · container SG
```

Each layer reads the previous layer's outputs via `terraform_remote_state` (local backend).

### CI/CD Pipeline

```
git push → main
      │
      ▼
GitHub Actions
      ├── test:   npm ci → lint → npm test
      └── deploy: (needs: test)
              ├── Configure AWS credentials
              ├── Login to ECR
              ├── Build Docker image (multi-stage + GHA layer cache)
              ├── Push  web-app-<commit>  +  web-app-latest-dev  tags
              ├── Render new ECS task definition revision
              ├── Deploy to ECS Fargate (waits for stability)
              ├── Print deployment summary to Actions UI
              └── Post-deployment health check via ECS API
```

---

## Repository Structure

```
Damolak/
├── README.md
│
├── app/                               # Next.js 15 application
│   ├── .aws/
│   │   └── task-def.json              # ECS task definition skeleton (used by CI/CD)
│   ├── .github/
│   │   └── workflows/
│   │       └── deploy.yml             # GitHub Actions pipeline
│   ├── src/app/
│   │   ├── api/health/route.ts        # GET /api/health → { status, timestamp }
│   │   ├── page.tsx                   # Homepage (reads API_BASE_URL from env)
│   │   ├── layout.tsx
│   │   └── globals.css
│   ├── Dockerfile                     # Multi-stage build (deps → builder → runner)
│   ├── .dockerignore
│   ├── next.config.ts                 # output: "standalone"
│   ├── package.json
│   └── tsconfig.json
│
└── infra/
    ├── shared/                        # Layer 1 — Networking
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── main.tf                    # VPC, subnets, IGW, NAT, route tables
    │   ├── outputs.tf
    │   └── terraform.tfvars
    │
    ├── platform/                      # Layer 2 — Platform services
    │   ├── providers.tf
    │   ├── variables.tf
    │   ├── externals.tf               # reads shared state
    │   ├── ecr.tf                     # ECR repository + lifecycle policy
    │   ├── iam.tf                     # ECS execution role + task role
    │   ├── ecs-cluster.tf             # ECS cluster (Fargate + Fargate Spot)
    │   ├── alb.tf                     # ALB, security group, HTTP listener
    │   ├── outputs.tf
    │   └── terraform.tfvars
    │
    └── web-app/                       # Layer 3 — Service resources
        ├── providers.tf
        ├── variables.tf
        ├── externals.tf               # reads shared + platform state
        ├── locals.tf                  # env/secrets transformation
        ├── ecs-task.tf
        ├── ecs-service.tf             # ECS service + auto scaling
        ├── alb.tf                     # target group + listener rule
        ├── secrets.tf                 # Secrets Manager (API_BASE_URL only)
        ├── security-groups.tf
        ├── cloudwatch.tf
        ├── outputs.tf
        ├── values-dev.tfvars
        └── values-prod.tfvars
```

---

## Prerequisites

- Terraform >= 1.0
- AWS CLI v2 (configured with credentials)
- Docker
- Node.js 20

---

## Deployment Steps

### 1. Deploy shared networking

```bash
cd infra/shared
terraform init
terraform fmt
terraform validate
terraform plan -out=devplan.tfplan -var-file=terraform.tfvars
terraform apply "devplan.tfplan"
```

### 2. Deploy platform services

```bash
cd infra/platform
terraform init
terraform fmt
terraform validate
terraform plan -out=devplan.tfplan -var-file=terraform.tfvars
terraform apply "devplan.tfplan"
```

This creates the ECR repository, IAM roles, ECS cluster, and ALB. Note the ALB DNS name from the output — you can point a domain or CNAME to it.

### 3. Deploy the web-app service

```bash
cd infra/web-app
terraform init
terraform init
terraform fmt
terraform validate
terraform plan -out=devplan.tfplan -var-file=values-dev.tfvars
terraform apply "devplan.tfplan"
```

### 4. Set the real API_BASE_URL secret

Terraform creates the secret with a placeholder value. Update it before the first deploy:

```bash
aws secretsmanager put-secret-value \
  --secret-id dev-web-app-secrets \
  --secret-string '{"API_BASE_URL":"https://your-real-api.example.com"}' \
  --region eu-west-1
```

### 5. Push the initial Docker image

Before ECS can run a task, the ECR image must exist. Trigger CI/CD with the first push to `main`, or push manually:

```bash
aws ecr get-login-password --region eu-west-1 | \
  docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com

docker build -t web-app-ecr:web-app-latest-dev ./app
docker tag web-app-ecr:web-app-latest-dev \
  ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/web-app-ecr:web-app-latest-dev
docker push ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com/web-app-ecr:web-app-latest-dev
```

### 6. Configure GitHub Actions secrets

In **GitHub → Settings → Environments → development → Secrets**:

| Secret | Value |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM access key |
| `AWS_SECRET_ACCESS_KEY` | IAM secret key |
| `AWS_REGION` | `eu-west-1` |
| `ECR_REPOSITORY` | `web-app-ecr` |

Subsequent deploys happen automatically on every push to `main`.

---

## Monitoring & Logging

### CloudWatch Logs

```
Log group:  dev-web-app-logs
Log stream: dev-web-app/<task-id>
Retention:  30 days
```

Tail logs live:

```bash
aws logs tail dev-web-app-logs --follow --region eu-west-1
```

### Health Check

The ALB polls `GET /api/health` every 10 seconds:

```json
{ "status": "ok", "timestamp": "2026-05-11T10:00:00.000Z" }
```

Two consecutive failures → task marked unhealthy → ECS replaces it automatically.

### ECS Container Insights

Enabled on the cluster — view CPU, memory, and task counts in CloudWatch Container Insights without any extra configuration.

---

## Design Decisions

### Layered Terraform (shared → platform → web-app)
Separating networking, platform services, and the application service into three independent state files means you can update the app service without touching the VPC or cluster. Cross-layer data is shared via `terraform_remote_state` with the local backend — clean, no remote backend required.

### Local Terraform state
Local state keeps the setup self-contained and dependency-free. For a team environment, migrating to an S3 backend with DynamoDB locking is a one-line change to `backend "local" {}` in each `providers.tf`.

### Private subnets for ECS tasks
ECS containers live in private subnets with no public IPs. All outbound traffic (ECR image pull, Secrets Manager, CloudWatch) routes via a NAT Gateway. Inbound traffic only enters through the ALB. This removes the tasks from direct internet exposure.

### Single NAT Gateway (dev)
A NAT Gateway in one AZ keeps dev costs low. Production would use one NAT per AZ to eliminate the cross-AZ data transfer charge and provide AZ-level resilience.

### HTTP only on the ALB
For the assessment, the ALB listener is plain HTTP. Production would add an ACM certificate and replace the HTTP listener with an HTTP→HTTPS redirect plus an HTTPS listener — a two-resource change in `platform/alb.tf`.

### Only one secret (API_BASE_URL)
All other configuration (`PORT`, `AWS_REGION`, `NODE_ENV`) is non-sensitive and set as plain environment variables in the task definition. Minimising the Secrets Manager surface area reduces IAM policy scope and secret rotation complexity.

### `output: "standalone"` in Next.js
The standalone output traces only the files the app actually uses, producing a self-contained `server.js`. The Docker image shrinks significantly (no full `node_modules` at runtime) and cold-start time drops.

### Image tagging strategy
| Tag | Example | Purpose |
|---|---|---|
| Versioned | `web-app-a1b2c3d` | Immutable — directly traceable to a commit, enables instant rollback |
| Rolling | `web-app-latest-dev` | Used as the baseline image in `task-def.json` |

---

## Limitations & Improvements

| Area | Current | Improvement |
|---|---|---|
| HTTPS | HTTP only | Add ACM cert → HTTP redirect + HTTPS listener in `platform/alb.tf` |
| Terraform state | Local | Migrate `backend "local"` → `backend "s3"` with DynamoDB locking for teams |
| NAT Gateway | Single AZ (dev) | Add one NAT per AZ in prod for AZ resilience |
| Tests | Lint + stub test | Add Jest unit tests and Playwright e2e |
| ECR scanning | Scan on push only | Enable ECR enhanced scanning with Inspector |
| Alerting | Logs only | Add CloudWatch alarms on ALB 5xx rate and ECS unhealthy task count |
| Secrets rotation | Manual CLI | Enable automatic rotation via Secrets Manager Lambda rotator |
| CD environments | Dev only automated | Add `deploy-prod.yml` with a manual approval gate |
