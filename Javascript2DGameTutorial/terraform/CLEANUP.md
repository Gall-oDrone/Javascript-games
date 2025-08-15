# EKS Infrastructure Cleanup Guide

This guide explains how to safely clean up the EKS infrastructure using the updated cleanup script.

## Quick Usage

### Basic Cleanup (with confirmation)
```bash
./cleanup.sh dev
```

### Force Cleanup (skip confirmation)
```bash
./cleanup.sh dev --force
```

### Cleanup Orphaned Resources Only
```bash
./cleanup.sh dev --cleanup-orphaned
```

## What the Cleanup Script Does

### 1. Safe Kubernetes Resource Cleanup
The script first checks if the EKS cluster exists and is accessible, then:
- Uninstalls Helm releases (AWS Load Balancer Controller, Metrics Server, Karpenter, Cert Manager)
- Deletes Kubernetes namespaces and service accounts
- Removes application resources

### 2. Terraform Infrastructure Destruction
- Plans and applies Terraform destruction
- Removes all AWS resources (EKS cluster, VPC, ECR, IAM roles, etc.)

### 3. Orphaned Resource Detection
- Checks for orphaned load balancers
- Identifies orphaned security groups
- Reports orphaned IAM roles

## Troubleshooting

### If the Cluster Was Already Manually Deleted

If you manually deleted the EKS cluster and Terraform is failing to delete Kubernetes resources:

```bash
# Clean up orphaned resources from Terraform state
./cleanup.sh dev --cleanup-orphaned

# Then run normal cleanup
./cleanup.sh dev
```

### Manual Cleanup Steps

If the script fails, you can manually clean up:

1. **Remove Kubernetes resources from Terraform state:**
```bash
cd environments/dev
terraform state rm module.addons.kubernetes_service_account.aws_load_balancer_controller[0]
terraform state rm module.addons.helm_release.aws_load_balancer_controller[0]
terraform state rm module.addons.helm_release.metrics_server[0]
terraform state rm module.addons.helm_release.karpenter[0]
terraform state rm module.addons.helm_release.cert_manager[0]
terraform state rm module.application.kubernetes_namespace.this
terraform state rm module.application.kubernetes_deployment.this
terraform state rm module.application.kubernetes_service.this
terraform state rm module.application.kubernetes_horizontal_pod_autoscaler.this
terraform state rm module.application.kubernetes_ingress_v1.this
```

2. **Run Terraform destroy:**
```bash
terraform destroy
```

### Common Error Messages and Solutions

#### "Kubernetes cluster unreachable"
- **Cause**: Cluster was manually deleted
- **Solution**: Use `--cleanup-orphaned` flag

#### "0-length response with status code: 200"
- **Cause**: Kubernetes API server is unreachable
- **Solution**: Use `--cleanup-orphaned` flag

#### "Permission denied" errors
- **Cause**: Insufficient AWS permissions
- **Solution**: Ensure your AWS credentials have proper permissions

## Environment-Specific Cleanup

The script automatically detects the environment structure:
- `environments/dev/` - Development environment
- `environments/prod/` - Production environment
- `environments/staging/` - Staging environment

## Safety Features

- **Confirmation prompts** (unless `--force` is used)
- **Cluster existence checks** before attempting operations
- **Graceful error handling** for unreachable clusters
- **Orphaned resource detection** and reporting
- **Comprehensive logging** of all operations

## Best Practices

1. **Always use the cleanup script** instead of manual deletion
2. **Test in dev environment** before production cleanup
3. **Review the plan** before applying destruction
4. **Check for orphaned resources** after cleanup
5. **Keep backups** of important data before cleanup
