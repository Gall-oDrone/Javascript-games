#!/bin/bash

# Apply Fixed IAM Policy Script
# This script applies the updated IAM policy to resolve launch template authorization issues

set -e

echo "🔧 Applying Fixed IAM Policy..."

# Get current user/role name
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo "Current user/role: $CURRENT_USER"

# Create the fixed policy
echo "📝 Creating fixed IAM policy..."
aws iam create-policy \
    --policy-name "EKSFixedAccessPolicy" \
    --policy-document file://fixed-iam-policy.json \
    --description "Fixed EKS access policy with launch template permissions" \
    || echo "Policy already exists or error occurred"

# Attach policy to current user/role
echo "🔗 Attaching policy to current user/role..."
if [[ $CURRENT_USER == *"user"* ]]; then
    # It's a user
    aws iam attach-user-policy \
        --user-name $CURRENT_USER \
        --policy-arn "arn:aws:iam::654654565400:policy/EKSFixedAccessPolicy"
    echo "✅ Policy attached to user: $CURRENT_USER"
else
    # It's a role
    aws iam attach-role-policy \
        --role-name $CURRENT_USER \
        --policy-arn "arn:aws:iam::654654565400:policy/EKSFixedAccessPolicy"
    echo "✅ Policy attached to role: $CURRENT_USER"
fi

# Create required service-linked roles
echo "🔧 Creating required service-linked roles..."
aws iam create-service-linked-role --aws-service-name eks.amazonaws.com || echo "EKS service-linked role already exists"
aws iam create-service-linked-role --aws-service-name eks-nodegroup.amazonaws.com || echo "EKS nodegroup service-linked role already exists"
aws iam create-service-linked-role --aws-service-name eks-fargate.amazonaws.com || echo "EKS fargate service-linked role already exists"

echo "✅ Fixed IAM policy applied successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Wait 5-10 minutes for IAM changes to propagate"
echo "2. Run: ./phase1-test.sh test dev"
echo "3. If successful, run: ./phase1-test.sh deploy dev"
echo ""
echo "⚠️  Note: If you still get authorization errors, you may need to:"
echo "   - Use a different AWS account with admin privileges"
echo "   - Or temporarily attach AdministratorAccess policy for testing" 