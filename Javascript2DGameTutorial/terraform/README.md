# Terraform AWS EKS Deployment for JavaScript 2D Game

This directory contains Terraform configurations to deploy the JavaScript 2D Game to AWS EKS (Elastic Kubernetes Service).

## 🚀 **Recent Fixes (v2.0)**

### **VPC Subnet Configuration Fix**
- **Issue**: Fixed "empty tuple" errors when creating public subnets
- **Root Cause**: Hardcoded subnet CIDRs didn't match available AZs in the region
- **Solution**: Dynamic subnet CIDR generation based on available AZs
- **Benefits**: 
  - Works across all AWS regions with different AZ counts
  - Automatically adapts to region-specific configurations
  - No more manual subnet CIDR configuration needed

### **Key Changes**
1. **Dynamic Subnet Generation**: Subnet CIDRs are now calculated automatically
2. **AZ Validation**: Added validation to ensure sufficient AZs are available
3. **Enhanced Outputs**: Added debugging outputs for VPC and subnet information
4. **Validation Script**: New `validate.sh` script for pre-deployment checks

## 📁 **File Structure**

```
terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Input variables
├── environments/           # Environment-specific configurations
│   ├── dev.tfvars         # Development environment
│   └── prod.tfvars        # Production environment
├── k8s/                   # Kubernetes manifests
│   └── deployment.yaml    # Game deployment configuration
├── deploy.sh              # Deployment automation script
├── validate.sh            # Validation and debugging script
└── README.md              # This file
```

## 🏗️ **Architecture Overview**

The deployment creates the following AWS resources:

### **Networking**
- **VPC**: Custom VPC with dynamic subnet configuration
- **Subnets**: Public and private subnets (one per AZ)
- **NAT Gateways**: For private subnet internet access
- **Route Tables**: Proper routing configuration

### **Compute & Container**
- **EKS Cluster**: Managed Kubernetes cluster
- **Node Groups**: Auto-scaling worker nodes
- **ECR Repository**: Docker image storage

### **Load Balancing & Ingress**
- **Application Load Balancer**: Internet-facing load balancer
- **Ingress Controller**: AWS Load Balancer Controller
- **SSL/TLS**: HTTPS termination (optional)

### **Monitoring & Scaling**
- **Horizontal Pod Autoscaler**: Automatic scaling based on CPU/memory
- **CloudWatch**: Logging and monitoring (optional)

## 🚀 **Quick Start**

### **Prerequisites**
1. **AWS CLI** configured with appropriate permissions
2. **Terraform** (version >= 1.0)
3. **kubectl** for Kubernetes management
4. **Docker** for building images

### **Required AWS Permissions**
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:*",
                "eks:*",
                "iam:*",
                "ecr:*",
                "elasticloadbalancing:*",
                "autoscaling:*",
                "cloudwatch:*",
                "logs:*",
                "s3:*"
            ],
            "Resource": "*"
        }
    ]
}
```

### **Step 1: Validate Configuration**
```bash
# Check AWS configuration and validate Terraform
./validate.sh check

# Show configuration summary
./validate.sh summary dev
```

### **Step 2: Deploy Infrastructure**
```bash
# Deploy to development environment
./deploy.sh deploy dev

# Deploy to production environment
./deploy.sh deploy prod
```

### **Step 3: Verify Deployment**
```bash
# Get deployment status
./deploy.sh status

# Get cluster info
aws eks describe-cluster --name javascript-2d-game-dev --region us-west-2
```

## 🔧 **Configuration Options**

### **Environment Variables**

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `aws_region` | AWS region | `us-west-2` | `us-east-1` |
| `environment` | Environment name | `dev` | `prod` |
| `cluster_name` | EKS cluster name | `javascript-2d-game-cluster` | Custom name |
| `game_replicas` | Number of game pods | `2` | `5` |
| `node_group_desired_size` | Desired node count | `2` | `3` |
| `container_cpu_limit` | CPU limit per pod | `500m` | `1000m` |

### **Dynamic Subnet Configuration**
The VPC now automatically generates subnet CIDRs based on available AZs:

- **Private Subnets**: `10.0.1.0/24`, `10.0.2.0/24`, etc. (one per AZ)
- **Public Subnets**: `10.0.101.0/24`, `10.0.102.0/24`, etc. (one per AZ)

This ensures compatibility across all AWS regions.

## 🛠️ **Troubleshooting**

### **Common Issues**

#### **1. VPC Subnet Errors**
```bash
# Error: aws_subnet.public is empty tuple
# Solution: Use the updated configuration with dynamic subnet generation
```

#### **2. AZ Count Issues**
```bash
# Check available AZs in your region
aws ec2 describe-availability-zones --region us-west-2

# Use validate.sh to check configuration
./validate.sh check
```

#### **3. EKS Cluster Creation Fails**
```bash
# Check IAM permissions
aws sts get-caller-identity

# Verify VPC configuration
terraform output vpc_id
terraform output private_subnets
```

### **Debugging Commands**
```bash
# Validate Terraform configuration
terraform validate

# Check what will be created
terraform plan -var-file=environments/dev.tfvars

# View outputs
terraform output

# Check EKS cluster status
aws eks describe-cluster --name javascript-2d-game-dev --region us-west-2
```

## 📊 **Monitoring & Logs**

### **CloudWatch Logs**
```bash
# View EKS cluster logs
aws logs describe-log-groups --log-group-name-prefix "/aws/eks/javascript-2d-game"

# View application logs
kubectl logs -n javascript-2d-game deployment/javascript-2d-game
```

### **Resource Monitoring**
```bash
# Check pod status
kubectl get pods -n javascript-2d-game

# Check HPA status
kubectl get hpa -n javascript-2d-game

# Check service endpoints
kubectl get endpoints -n javascript-2d-game
```

## 🔄 **Updates & Maintenance**

### **Updating the Game**
```bash
# Build and push new Docker image
docker build -t javascript-2d-game .
docker tag javascript-2d-game:latest $ECR_REPO_URL:latest
docker push $ECR_REPO_URL:latest

# Update Kubernetes deployment
kubectl rollout restart deployment/javascript-2d-game -n javascript-2d-game
```

### **Scaling**
```bash
# Scale manually
kubectl scale deployment javascript-2d-game --replicas=5 -n javascript-2d-game

# Update HPA
kubectl patch hpa javascript-2d-game-hpa -n javascript-2d-game -p '{"spec":{"maxReplicas":15}}'
```

## 🧹 **Cleanup**

### **Destroy Resources**
```bash
# Destroy everything
./deploy.sh destroy dev

# Or manually
terraform destroy -var-file=environments/dev.tfvars
```

### **Cleanup S3 Backend**
```bash
# Remove Terraform state bucket
aws s3 rb s3://javascript-2d-game-terraform-state --force
```

## 📚 **Additional Resources**

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)

## 🤝 **Support**

For issues related to:
- **Terraform Configuration**: Check the troubleshooting section above
- **AWS Services**: Refer to AWS documentation
- **Kubernetes**: Check kubectl commands and logs
- **Game Application**: Check application logs and health endpoints

---

**Note**: This configuration is designed for production use with proper security, monitoring, and scaling capabilities. Always test in a development environment first. 