# JavaScript 2D Game - AWS EKS Deployment with Terraform

This Terraform configuration deploys your JavaScript 2D game with AI agent to AWS EKS, following modern engineering practices from the [AWS AppMod Blueprints](https://github.com/aws-samples/appmod-blueprints/tree/main).

## 🏗️ Architecture Overview

The deployment creates a complete AWS infrastructure including:

- **VPC** with public and private subnets across multiple AZs
- **EKS Cluster** with managed node groups
- **ECR Repository** for Docker image storage
- **Application Load Balancer** for traffic distribution
- **Kubernetes Resources** (Deployment, Service, Ingress, HPA)
- **Auto-scaling** based on CPU and memory utilization

## 📁 File Structure

```
terraform/
├── main.tf                 # Main Terraform configuration
├── variables.tf            # Variable definitions
├── deploy.sh              # Deployment automation script
├── environments/
│   ├── dev.tfvars         # Development environment config
│   └── prod.tfvars        # Production environment config
├── k8s/
│   └── deployment.yaml    # Kubernetes manifests
└── README.md              # This file
```

## 🚀 Quick Start

### Prerequisites

1. **AWS CLI** configured with appropriate permissions
2. **Terraform** >= 1.0
3. **kubectl** for Kubernetes management
4. **Docker** for building images

### Installation

```bash
# Clone the repository
git clone <your-repo>
cd Javascript2DGameTutorial/terraform

# Make deployment script executable
chmod +x deploy.sh

# Initialize and deploy to development environment
./deploy.sh init
./deploy.sh deploy dev
```

### Deployment Commands

```bash
# Initialize prerequisites and backend
./deploy.sh init

# Deploy infrastructure and application
./deploy.sh deploy [environment]

# Deploy only infrastructure
./deploy.sh infrastructure [environment]

# Deploy only application
./deploy.sh application

# Check deployment status
./deploy.sh status

# Destroy infrastructure
./deploy.sh destroy [environment]
```

## 🌍 Environment Configuration

### Development Environment (`dev.tfvars`)

- **EKS Cluster**: Single node group with t3.medium instances
- **Replicas**: 1 game instance
- **Resources**: Lower CPU/memory limits for cost optimization
- **Autoscaling**: 1-3 replicas
- **Monitoring**: Enabled
- **Backup**: Disabled

### Production Environment (`prod.tfvars`)

- **EKS Cluster**: Multiple node groups with t3.large instances
- **Replicas**: 3 game instances
- **Resources**: Higher CPU/memory limits for performance
- **Autoscaling**: 2-10 replicas
- **Monitoring**: Enabled
- **Backup**: Enabled

## 🔧 Configuration Options

### Core Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for deployment | `us-west-2` |
| `environment` | Environment name | `dev` |
| `cluster_name` | EKS cluster name | `javascript-2d-game-cluster` |
| `game_replicas` | Number of game replicas | `2` |

### Networking

| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | VPC CIDR block | `10.0.0.0/16` |
| `private_subnet_cidrs` | Private subnet CIDRs | `["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]` |
| `public_subnet_cidrs` | Public subnet CIDRs | `["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]` |

### Scaling

| Variable | Description | Default |
|----------|-------------|---------|
| `hpa_min_replicas` | Minimum HPA replicas | `1` |
| `hpa_max_replicas` | Maximum HPA replicas | `10` |
| `hpa_cpu_target` | CPU target percentage | `70` |
| `hpa_memory_target` | Memory target percentage | `80` |

## 🎮 Game Features

The deployed game includes:

- **AI Agent**: Press 'A' to toggle AI mode
- **Difficulty Levels**: Press 'D' to cycle through Easy/Medium/Hard
- **Auto-scaling**: Automatically scales based on load
- **Load Balancing**: Traffic distributed across multiple instances
- **Health Checks**: Automatic health monitoring and recovery

## 🔒 Security Features

- **VPC Isolation**: Private subnets for EKS nodes
- **Security Groups**: Restrictive network access
- **IAM Roles**: Least privilege access
- **ECR Scanning**: Automatic vulnerability scanning
- **SSL/TLS**: HTTPS support with automatic redirect

## 📊 Monitoring and Observability

### CloudWatch Integration

- **Container Insights**: Automatic EKS monitoring
- **Log Aggregation**: Centralized logging
- **Metrics**: CPU, memory, and network metrics
- **Alarms**: Automatic alerting for issues

### Kubernetes Monitoring

- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: CPU and memory constraints
- **Auto-scaling**: Horizontal Pod Autoscaler
- **Load Balancing**: Application Load Balancer

## 🔄 CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy to AWS EKS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v2
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: us-west-2
    
    - name: Deploy to EKS
      run: |
        cd terraform
        ./deploy.sh deploy prod
```

## 🛠️ Troubleshooting

### Common Issues

1. **ECR Repository Not Found**
   ```bash
   # Deploy infrastructure first
   ./deploy.sh infrastructure dev
   ```

2. **Kubernetes Connection Issues**
   ```bash
   # Update kubeconfig
   aws eks update-kubeconfig --region us-west-2 --name your-cluster-name
   ```

3. **Image Pull Errors**
   ```bash
   # Check ECR login
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin your-ecr-url
   ```

### Debug Commands

```bash
# Check pod status
kubectl get pods -n javascript-2d-game

# View pod logs
kubectl logs -n javascript-2d-game deployment/javascript-2d-game

# Check service status
kubectl get svc -n javascript-2d-game

# Check ingress status
kubectl get ingress -n javascript-2d-game
```

## 💰 Cost Optimization

### Development Environment

- Use spot instances for cost savings
- Reduce replica count to minimum
- Use smaller instance types
- Disable unnecessary monitoring

### Production Environment

- Use reserved instances for predictable costs
- Implement proper resource limits
- Monitor and optimize resource usage
- Use auto-scaling to handle traffic spikes

## 🔄 Updates and Maintenance

### Updating the Application

```bash
# Build and push new image
docker build -t your-ecr-url:latest ..
docker push your-ecr-url:latest

# Update deployment
kubectl rollout restart deployment/javascript-2d-game -n javascript-2d-game
```

### Infrastructure Updates

```bash
# Plan changes
terraform plan -var-file=environments/dev.tfvars

# Apply changes
terraform apply -var-file=environments/dev.tfvars
```

## 📚 Additional Resources

- [AWS AppMod Blueprints](https://github.com/aws-samples/appmod-blueprints/tree/main)
- [EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the deployment
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details. 