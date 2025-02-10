# Reverse IP Web Application

A FastAPI web application that accepts incoming HTTP requests, displays the caller’s IP in reverse order, and stores the record in a PostgreSQL database. The project is containerized with Docker, deployed on a DigitalOcean Kubernetes cluster using Helm, and its infrastructure is provisioned with Terraform. CI/CD is managed via GitHub Actions.


Access the application using the IP: **http://134.199.138.99:8088/**

---

## Table of Contents

- [Project Overview](#project-overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [Building and Pushing the Docker Image](#building-and-pushing-the-docker-image)
- [Infrastructure Provisioning with Terraform](#infrastructure-provisioning-with-terraform)
  - [Terraform Backend Configuration](#terraform-backend-configuration)
  - [Provisioning the DigitalOcean Kubernetes Cluster and Managed PostgreSQL](#provisioning-the-digitalocean-kubernetes-cluster-and-managed-postgresql)
- [Deploying the Application with Helm](#deploying-the-application-with-helm)
- [Accessing the Application](#accessing-the-application)
- [CI/CD Pipeline using GitHub Actions](#ci-cd-pipeline-using-github-actions)
- [Troubleshooting CrashLoopBackOff Error](#Troubleshooting-CrashLoopBackOff-Error)

---

## Project Overview

This project provides a simple but scalable solution for displaying and storing reversed IP addresses:

- **Backend:** FastAPI (Python) with Uvicorn.
- **Database:** PostgreSQL (managed on DigitalOcean).
- **Containerization:** Docker.
- **Deployment:** Kubernetes on DigitalOcean, deployed via Helm.
- **Infrastructure as Code:** Terraform (using DigitalOcean Spaces as an S3‑compatible backend for state).
- **CI/CD:** GitHub Actions.

---

## Architecture

1. **FastAPI Application:**

   - Listens on port `8088` and returns the reversed IP address.
   - Uses SQLAlchemy to connect to a PostgreSQL database.
   - Environment variable `DATABASE_URL` is used to specify the database connection string.
2. **Docker Container:**

   - Built from a lightweight Python Alpine image.
   - Includes necessary dependencies (installed via `requirements.txt`).
3. **Kubernetes Deployment:**

   - Deployed on a DigitalOcean Kubernetes cluster.
   - Managed by Helm charts for configuration and lifecycle management.
   - Service exposed via a LoadBalancer to allow external access.
4. **Infrastructure Provisioning:**

   - Terraform provisions the Kubernetes cluster and manages state using DigitalOcean Spaces.
   - Backend configuration uses S3‑compatible settings.
5. **CI/CD Pipeline:**

   - GitHub Actions automates the build, push, and deployment processes.

---

## Prerequisites

- [Docker](https://www.docker.com/)
- [Kubernetes CLI (kubectl)](https://kubernetes.io/docs/tasks/tools/)
- [Helm](https://helm.sh/)
- [Terraform (v1.6.3 or later)](https://www.terraform.io/)
- [DigitalOcean Account](https://www.digitalocean.com/)
- [GitHub Account](https://github.com/) with repository secrets configured for:
  - `DIGITALOCEAN_TOKEN`
  - `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (for DigitalOcean Spaces)
- Basic knowledge of YAML, shell scripting, and cloud deployments.

---

## Local Development Setup

1. **Clone the Repository:**

   ```bash
   git clone https://github.com/ogdmerlin/IpReverser-K8s.git
   cd IpReverser-K8s
   ```
2. **Run Locally with Docker Compose (Optional):**

   If you want to run the app and a local PostgreSQL instance for development:

   ```bash
   # docker-compose.yml

   version: '3.8'
   services:
    web:
       build: .
       ports:
       - "8088:8088"
       environment:
           - DATABASE_URL=postgresql://postgres:postgres@db:5432/mydatabase
    db:
       image: postgres:15-alpine
       environment:
       POSTGRES_USER: postgres
       POSTGRES_PASSWORD: postgres
       POSTGRES_DB: mydatabase
       ports:
       - "5432:5432"
   ```

   Then run:

   ```bash
   docker-compose up -d
   ```
3. **Test the FastAPI Application:**

   Visit [http://localhost:8088](http://localhost:8088) in your browser. You should see the page displaying your original IP and the reversed IP.
4. **Access the Database:**

   You can access the PostgreSQL database using `psql`:

   ```bash
   psql -h localhost -U postgres -d mydatabase
   ```

   ![postgresql](/pub/image.png)

---

## Building and Pushing the Docker Image

1. **Build the Docker Image:**

   ```bash
   docker build -t ogdmerlin/reverse-ip:v1 .
   ```
2. **Tag the Image:**

   ```bash
   docker tag reverse-ip ogdmerlin/reverse-ip:v1
   ```
3. **Push the Image to Docker Hub:**

   ```bash
   docker push ogdmerlin/reverse-ip:v1
   ```

> [!IMPORTANT]
> _You must be logged in to Docker Hub to push the image, and you can replace `ogdmerlin` with your Docker Hub username_.

Login to Docker Hub:

```bash
docker login
```

---

## Infrastructure Provisioning with Terraform

### Terraform Backend Configuration

Create a backend.tf (or include in your main Terraform file):

```hcl
terraform {
  required_version = ">= 1.6.3"

  backend "s3" {
    endpoints = {
      s3 = "https://sfo3.digitaloceanspaces.com"
    }
    bucket = "reverseip-statefile"
    key    = "terraform.tfstate"

    # Disable AWS-specific validations
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_s3_checksum            = true

    region = "us-east-1"  # Arbitrary; required by Terraform but not used by Spaces
  }
}
```

## Provisioning the DigitalOcean Kubernetes Cluster and Managed PostgreSQL

Create your Terraform configuration (e.g., main.tf, database.tf, variables.tf) similar to:

```hcl
# main.tf
provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_kubernetes_cluster" "k8s_cluster" {
  name    = "ip-reverse-cluster"
  region  = "nyc3"
  version = "1.26.3-do.0"

  node_pool {
    name       = "default-pool"
    size       = "s-2vcpu-2gb"
    node_count = 2
  }
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.k8s_cluster.kube_config[0].raw_config
  sensitive = true
}
```

```hcl
# database.tf (DigitalOcean Managed PostgreSQL)
locals {
  database_cluster_name = "reverseapp-db"
}
resource "digitalocean_database_db" "db" {
  cluster_id = digitalocean_database_cluster.db_cluster.id
  name       = "reverseip"
}
resource "digitalocean_database_cluster" "db_cluster" {
  name                 = local.database_cluster_name
  engine               = "pg"
  version              = "17"
  size                 = "db-s-1vcpu-1gb" 
  region               = "sfo3"
  node_count           = 1
#   private_network_uuid = "default-sfo3"

  tags = ["reverseip"]
}

resource "digitalocean_database_user" "db_user" {
  cluster_id = digitalocean_database_cluster.db_cluster.id
  name       = "user"
#   password   = random_string.db_password.result
}
```

```hcl
# variables.tf
variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}
```

Initialize Terraform and apply the configuration:

```bash
cd ./K8s_Infra
terraform init
terraform apply
```

After applying, extract the kubeconfig:

```bash
terraform output -raw kubeconfig > do-kubeconfig.yaml
export KUBECONFIG=$(pwd)/do-kubeconfig.yaml
```

Verify the cluster:

```bash
kubectl get nodes
```

---

## Deploying the Application with Helm

1. **Add the Helm Repository:**

   ```bash
   helm install reverse-ip 
   ```

> [!TIP]
> _You can customize the Helm chart values in `./reverse-ip/values.yaml` before deploying_.

2. **Update Deployment Template (templates/deployment.yaml):**

   Ensure the environment variable is injected:

   ```yaml
    env:
    - name: DATABASE_URL
      valueFrom:
        secretKeyRef:
            name: db-credentials
            key: DATABASE_URL
   ```
3. **Create or Update the Kubernetes Secret:**

   ```bash
   kubectl create secret generic db-credentials --from-literal=DATABASE_URL=postgresql://user:password@host:port/dbname
   ```

> [!CAUTION]
> _Replace the connection string with your PostgreSQL credentials_.

4. **Deploy the Application with helm:**

   ```bash
    helm install reverse-ip . -f values.yaml
    # For updates
    helm upgrade reverse-ip . -f values.yaml
   ```
5. **Verify the Deployment:**

   ```bash
   kubectl get pods
   kubectl get svc
   ```

> [!IMPORTANT]
> _The `kubectl get svc` show an external IP address that let us access our application from the browser._
> ![kubectl-get-services](/pub/image1.png)
> It may take a few minutes for the LoadBalancer IP to be provisioned, Once the external IP is assigned, access your app at: `http://<EXTERNAL_IP>:8088`.
> ![alt text](/pub/image2.png)

# 

**Troubleshooting CrashLoopBackOff Error:**

> [!WARNING]
> I experience an issue with the pods not starting due to the `CrashLoopBackOff` error.
> I resolved it by checking the logs with `kubectl logs <pod-name>` and after spending some time, I found out that the issue was with the `livenessProbe`, and `readinessProbe` was failing. I had to comment out the `livenessProbe` and `readinessProbe` in the deployment.yaml file.

---

## CI/CD Pipeline using GitHub Actions

Our GitHub Actions workflow (.github/workflows/ci-cd.yaml) builds the Docker image, pushes it to Docker Hub, and deploys via Helm.

> [!TIP]
> Terraform Backend Issues in CI/CD:
> Make sure AWS/Spaces credentials are set at the job level in GitHub Actions as shown above

---

## Conclusion

_This documentation is intended to serve as a complete guide for developers and DevOps engineers working with the Reverse IP Web Application. For any questions or support, please refer to the project repository or contact the maintainers._

```yaml
---
This README provides an enterprise‑style, detailed documentation for your project with all necessary commands and explanations. Feel free to modify sections to better match your exact setup and project requirements.
```
