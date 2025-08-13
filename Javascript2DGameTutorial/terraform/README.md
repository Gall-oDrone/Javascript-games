# JavaScript 2D Game - Terraform Infrastructure

This directory contains the Terraform infrastructure code for deploying the JavaScript 2D Game on AWS EKS, following AWS Blueprints best practices.

## 🏗️ Architecture Overview

The infrastructure is designed using a modular approach with the following components:

- **VPC Module**: Network infrastructure with public and private subnets
- **EKS Module**: Kubernetes cluster with managed node groups
- **Addons Module**: EKS cluster addons and additional components
- **Application Module**: Game application deployment and ECR repository

## 📁 Directory Structure

```
terraform/
├── modules/                    # Reusable Terraform modules
│   ├── vpc/                   # VPC and networking
│   ├── eks/                   # EKS cluster and node groups
│   ├── addons/                # EKS addons and additional components
│   └── application/           # Application deployment
├── environments/              # Environment-specific configurations
│   ├── dev/                   # Development environment
│   ├── staging/               # Staging environment
│   └── prod/                  # Production environment
├── scripts/                   # Deployment and utility scripts
│   ├── deploy/                # Deployment scripts
│   ├── cleanup/               # Cleanup scripts
│   └── utils/                 # Utility scripts
├── docs/                      # Documentation
├── main-new.tf               # New modular main configuration
├── main.tf                   # Legacy monolithic configuration
├── variables.tf              # Global variables
├── outputs.tf                # Global outputs
└── versions.tf               # Provider versions
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate credentials
2. **Terraform** >= 1.0 installed
3. **kubectl** installed (optional, for post-deployment checks)
4. **S3 buckets** for Terraform state (create manually or use the provided script)

### Deployment

1. **Deploy to Development Environment**:
   ```bash
   ./scripts/deploy/deploy.sh -e dev -a apply
   ```

2. **Deploy to Production Environment**:
   ```bash
   ./scripts/deploy/deploy.sh -e prod -a apply -y
   ```

3. **Plan Changes Only**:
   ```bash
   ./scripts/deploy/deploy.sh -e dev -a plan
   ```

4. **Destroy Environment**:
   ```bash
   ./scripts/deploy/deploy.sh -e dev -a destroy
   ```

## 🔧 Configuration

### Environment Variables

Each environment has its own configuration in the `environments/` directory:

- **Development**: Minimal resources for testing
- **Production**: High availability with multiple AZs and larger instances

### Key Configuration Options

| Setting | Dev | Prod |
|---------|-----|------|
| Node Groups | 1-3 nodes | 2-6 nodes |
| Instance Types | t3.medium | t3.medium, t3.large |
| Availability Zones | 2 | 3 |
| Replicas | 1 | 3 |
| Resources | 500m CPU, 512Mi RAM | 1000m CPU, 1Gi RAM |

## 🏛️ Module Details

### VPC Module (`modules/vpc/`)

Creates a VPC with:
- Public and private subnets across multiple AZs
- NAT Gateways for private subnet internet access
- Proper tagging for EKS integration

### EKS Module (`modules/eks/`)

Deploys an EKS cluster with:
- Modern Access Entry API authentication
- KMS encryption for secrets
- Managed node groups with IRSA
- EBS CSI Driver integration

### Addons Module (`modules/addons/`)

Installs essential EKS addons:
- CoreDNS for service discovery
- VPC CNI for networking
- kube-proxy for service routing
- AWS Load Balancer Controller
- Metrics Server for HPA

### Application Module (`modules/application/`)

Deploys the game application:
- ECR repository with lifecycle policies
- Kubernetes namespace, deployment, service, and ingress
- Health checks and resource limits

## 🔐 Security Features

- **KMS Encryption**: All EKS secrets are encrypted at rest
- **IRSA**: IAM roles for service accounts
- **Private Subnets**: Worker nodes run in private subnets
- **Security Groups**: Restrictive security group rules
- **IAM Policies**: Least privilege access

## 📊 Monitoring and Logging

The infrastructure includes:
- CloudWatch metrics for EKS
- Container insights (optional)
- Metrics Server for HPA
- Load balancer access logs

## 🔄 CI/CD Integration

The modular structure supports:
- Environment-specific deployments
- GitOps workflows
- Progressive delivery
- Blue-green deployments

## 🛠️ Maintenance

### Updating Kubernetes Version

1. Update the `kubernetes_version` variable in environment configurations
2. Run terraform plan to see changes
3. Apply changes during maintenance window

### Scaling Node Groups

1. Modify the `node_groups` configuration in environment files
2. Apply changes with terraform

### Adding New Addons

1. Update the `modules/addons/main.tf` file
2. Configure the addon in environment configurations
3. Apply changes

## 🚨 Troubleshooting

### Common Issues

1. **Terraform State Lock**: Check S3 bucket for stale locks
2. **EKS Cluster Not Ready**: Wait for cluster to be fully provisioned
3. **Addon Installation Failures**: Check EKS addon compatibility

### Debug Commands

```bash
# Check cluster status
aws eks describe-cluster --name <cluster-name> --region us-west-2

# Get node status
kubectl get nodes

# Check addon status
kubectl get pods -n kube-system

# View terraform state
terraform show
```

## 📚 References

- [AWS EKS Blueprints](https://github.com/aws-ia/terraform-aws-eks-blueprints)
- [AWS AppMod Blueprints](https://github.com/aws-samples/appmod-blueprints)
- [Terraform EKS Module](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

## 🤝 Contributing

1. Follow the modular structure
2. Add proper documentation
3. Test changes in dev environment first
4. Update this README for significant changes

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 