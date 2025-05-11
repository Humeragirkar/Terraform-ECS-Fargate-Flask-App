# Terraform ECS Fargate Flask App Deployment
Deploy a containerized **Flask application** on **AWS ECS Fargate** using **Terraform**.
This setup automates the creation of networking (VPC, subnets, route tables), security groups, IAM roles, and ECS infrastructure.
The Flask app is built using **Docker**, pushed to **Amazon ECR**, and deployed via an **ECS Fargate service.**

---

## Deployment Steps with Commands

### 1. Initialize Terraform

```bash
terraform init
```

### 2. Preview the Infrastructure

```bash
terraform plan
```

### 3. Apply the Terraform Configuration

```bash
terraform apply
```

> Confirm with `yes` when prompted.

---

## 🐳 Docker Commands

### 1. Build Docker Image

```bash
docker build -t python-app .
```

### 2. Authenticate Docker to ECR

```bash
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <your-account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### 3. Tag and Push Image to ECR

```bash
docker tag python-app:latest <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/python-app:latest

docker push <your-account-id>.dkr.ecr.us-east-1.amazonaws.com/python-app:latest
```

---

##  AWS CLI Commands

### Configure AWS Credentials

```bash
aws configure
```

> You'll be prompted to enter your AWS Access Key, Secret Key, default region (e.g. `us-east-1`), and output format.


## Clean Up – Destroying the Resources

To avoid ongoing charges and clean up all the AWS infrastructure created by Terraform, run:

```bash
terraform destroy
```

> Confirm with `yes` when prompted.
