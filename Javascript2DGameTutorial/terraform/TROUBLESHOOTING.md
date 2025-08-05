# Troubleshooting Guide

This guide helps you resolve common issues when deploying the JavaScript 2D Game on EKS with AWS Load Balancer Controller.

## Common Issues and Solutions

### 1. AWS Load Balancer Controller Add-on Version Error

**Error:**
```
Error: reading EKS Add-On version info (aws-load-balancer-controller, 1.33): empty result
```

**Solution:**
- The AWS Load Balancer Controller is now installed via Helm instead of EKS add-ons
- This provides better control and follows AWS best practices
- The controller is automatically installed during Terraform deployment

**Verification:**
```bash
kubectl get pods -n kube-system | grep aws-load-balancer-controller
```

### 2. IAM Authorization Error for Launch Templates

**Error:**
```
Error: creating EKS Node Group: operation error EKS: CreateNodegroup, 
InvalidRequestException: You are not authorized to launch instances with this launch template
```

**Solution:**
- Added comprehensive IAM permissions for both cluster and node group roles
- Includes permissions for launch template management, EC2 instance operations, and IAM role passing

**Verification:**
```bash
# Check IAM roles
aws iam get-role --role-name javascript-2d-game-dev-cluster-role
aws iam get-role --role-name javascript-2d-game-dev-node-group-role

# Check attached policies
aws iam list-attached-role-policies --role-name javascript-2d-game-dev-cluster-role
aws iam list-attached-role-policies --role-name javascript-2d-game-dev-node-group-role
```

### 3. AWS Load Balancer Controller Not Working

**Symptoms:**
- Ingress resources not creating load balancers
- Services of type LoadBalancer not provisioning ALBs/NLBs

**Troubleshooting Steps:**

1. **Check if the controller is running:**
   ```bash
   kubectl get pods -n kube-system | grep aws-load-balancer-controller
   ```

2. **Check controller logs:**
   ```bash
   kubectl logs -n kube-system deployment/aws-load-balancer-controller
   ```

3. **Verify IAM role for service account:**
   ```bash
   kubectl describe serviceaccount aws-load-balancer-controller -n kube-system
   ```

4. **Check OIDC provider:**
   ```bash
   aws eks describe-cluster --name javascript-2d-game-dev --query 'cluster.identity.oidc.issuer'
   ```

5. **Verify subnet tagging:**
   ```bash
   # Check public subnets
   aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/elb,Values=1"
   
   # Check private subnets
   aws ec2 describe-subnets --filters "Name=tag:kubernetes.io/role/internal-elb,Values=1"
   ```

### 4. Load Balancer Not Provisioning

**Common Causes:**
- Missing subnet tags
- Insufficient IAM permissions
- Controller not running
- Network configuration issues

**Solutions:**

1. **Verify subnet tags:**
   ```bash
   # Public subnets should have:
   # kubernetes.io/cluster/<cluster-name> = shared
   # kubernetes.io/role/elb = 1
   
   # Private subnets should have:
   # kubernetes.io/cluster/<cluster-name> = shared
   # kubernetes.io/role/internal-elb = 1
   ```

2. **Check security groups:**
   ```bash
   # Ensure node security group allows traffic on port 9443 from control plane
   aws ec2 describe-security-groups --group-ids <node-security-group-id>
   ```

3. **Verify VPC configuration:**
   ```bash
   # Check if VPC has DNS hostnames and DNS resolution enabled
   aws ec2 describe-vpcs --vpc-ids <vpc-id>
   ```

### 5. Pod Scheduling Issues

**Symptoms:**
- Pods stuck in Pending state
- Insufficient resources

**Troubleshooting:**

1. **Check node resources:**
   ```bash
   kubectl describe nodes
   kubectl top nodes
   ```

2. **Check pod events:**
   ```bash
   kubectl describe pod <pod-name> -n javascript-2d-game
   ```

3. **Check node group scaling:**
   ```bash
   aws eks describe-nodegroup --cluster-name javascript-2d-game-dev --nodegroup-name general
   ```

### 6. ECR Image Pull Issues

**Symptoms:**
- ImagePullBackOff errors
- Authentication failures

**Solutions:**

1. **Configure ECR authentication:**
   ```bash
   aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com
   ```

2. **Check ECR repository:**
   ```bash
   aws ecr describe-repositories --repository-names javascript-2d-game-game
   ```

3. **Verify image exists:**
   ```bash
   aws ecr describe-images --repository-name javascript-2d-game-game
   ```

## Debugging Commands

### Cluster Information
```bash
# Get cluster status
aws eks describe-cluster --name javascript-2d-game-dev

# Get node group status
aws eks describe-nodegroup --cluster-name javascript-2d-game-dev --nodegroup-name general

# Check cluster add-ons
aws eks list-addons --cluster-name javascript-2d-game-dev
```

### Kubernetes Resources
```bash
# Check all resources in the game namespace
kubectl get all -n javascript-2d-game

# Check events
kubectl get events -n javascript-2d-game --sort-by='.lastTimestamp'

# Check ingress status
kubectl describe ingress -n javascript-2d-game

# Check service status
kubectl describe service javascript-2d-game-service -n javascript-2d-game
```

### AWS Load Balancer Controller
```bash
# Check controller deployment
kubectl get deployment aws-load-balancer-controller -n kube-system

# Check controller logs
kubectl logs -f deployment/aws-load-balancer-controller -n kube-system

# Check controller events
kubectl get events -n kube-system | grep aws-load-balancer-controller
```

### Network and Security
```bash
# Check VPC endpoints
aws ec2 describe-vpc-endpoints --filters "Name=vpc-id,Values=<vpc-id>"

# Check security groups
aws ec2 describe-security-groups --filters "Name=group-name,Values=*javascript-2d-game*"

# Check load balancers
aws elbv2 describe-load-balancers
```

## Recovery Procedures

### 1. Reinstall AWS Load Balancer Controller
```bash
# Delete existing controller
kubectl delete deployment aws-load-balancer-controller -n kube-system

# Reapply Terraform to reinstall
terraform apply -var-file=environments/dev.tfvars
```

### 2. Recreate Node Group
```bash
# Delete node group
aws eks delete-nodegroup --cluster-name javascript-2d-game-dev --nodegroup-name general

# Wait for deletion, then reapply Terraform
terraform apply -var-file=environments/dev.tfvars
```

### 3. Reset Cluster State
```bash
# Destroy and recreate
./cleanup.sh dev --force
./deploy.sh dev
```

## Getting Help

If you're still experiencing issues:

1. **Check AWS Support**: For AWS service-specific issues
2. **Check EKS Documentation**: [EKS Best Practices](https://docs.aws.amazon.com/eks/latest/userguide/best-practices.html)
3. **Check AWS Load Balancer Controller Documentation**: [Installation Guide](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/)
4. **Review Terraform State**: `terraform show` to understand current state
5. **Check CloudWatch Logs**: For EKS control plane logs

## Prevention

To avoid these issues in the future:

1. **Always use the deployment script**: `./deploy.sh dev`
2. **Monitor cluster health**: Regular checks with `kubectl get nodes`
3. **Keep Terraform state clean**: Use `terraform plan` before applying
4. **Follow AWS best practices**: Use IRSA, proper tagging, and security groups
5. **Regular updates**: Keep EKS and controller versions up to date 