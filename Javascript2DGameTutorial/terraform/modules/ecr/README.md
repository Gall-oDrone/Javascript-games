# ECR Module

This module creates and manages an Amazon Elastic Container Registry (ECR) repository for storing Docker images.

## Features

- Creates ECR repository with configurable settings
- Lifecycle policies for image retention
- Image scanning on push
- Encryption support (AES256 or KMS)
- Pull through cache for Docker Hub (optional)
- Enhanced registry scanning (optional)
- Repository policies for cross-account access

## Usage

```hcl
module "ecr" {
  source = "../../modules/ecr"
  
  repository_name = "my-app-dev"
  environment     = "dev"
  
  # Optional configurations
  scan_on_push               = true
  enable_lifecycle_policy    = true
  max_image_count           = 30
  untagged_image_expiry_days = 7
  
  tags = {
    Project = "my-project"
    Owner   = "devops-team"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| repository_name | Name of the ECR repository | string | - | yes |
| environment | Environment name | string | - | yes |
| image_tag_mutability | Tag mutability setting (MUTABLE or IMMUTABLE) | string | "MUTABLE" | no |
| scan_on_push | Enable image scanning on push | bool | true | no |
| encryption_type | Encryption type (AES256 or KMS) | string | "AES256" | no |
| kms_key_arn | KMS key ARN for encryption | string | null | no |
| enable_lifecycle_policy | Enable lifecycle policy | bool | true | no |
| max_image_count | Maximum number of images to keep | number | 30 | no |
| untagged_image_expiry_days | Days to keep untagged images | number | 7 | no |
| protected_tags | Tag prefixes to protect from lifecycle | list(string) | ["prod", "release", "stable"] | no |
| tags | Tags to apply to resources | map(string) | {} | no |

## Outputs

| Name | Description |
|------|-------------|
| repository_url | The URL of the repository |
| repository_arn | Full ARN of the repository |
| repository_name | The name of the repository |
| registry_id | The registry ID |
| docker_login_command | Docker login command for ECR |
| docker_push_commands | Example commands to build, tag, and push |

## Examples

### Basic Repository

```hcl
module "ecr_basic" {
  source = "../../modules/ecr"
  
  repository_name = "my-app"
  environment     = "dev"
}
```

### Repository with KMS Encryption

```hcl
module "ecr_kms" {
  source = "../../modules/ecr"
  
  repository_name = "secure-app"
  environment     = "prod"
  encryption_type = "KMS"
  kms_key_arn    = aws_kms_key.ecr.arn
}
```

### Repository with Custom Lifecycle Policy

```hcl
module "ecr_custom" {
  source = "../../modules/ecr"
  
  repository_name            = "api-service"
  environment               = "staging"
  max_image_count           = 50
  untagged_image_expiry_days = 14
  protected_tags            = ["v1", "v2", "latest"]
  protected_tag_count       = 20
}
```

## Docker Commands

After creating the repository, you can use these commands:

```bash
# Get login token
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <registry-url>

# Build image
docker build -t my-app .

# Tag image
docker tag my-app:latest <repository-url>:latest

# Push image
docker push <repository-url>:latest
```