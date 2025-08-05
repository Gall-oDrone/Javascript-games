#!/bin/bash

# Temporary Admin Access Script
# WARNING: This grants AdministratorAccess - use only for testing!

set -e

echo "⚠️  WARNING: This script will grant AdministratorAccess to your current user/role!"
echo "This should only be used for testing purposes."
echo ""
read -p "Do you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Aborted."
    exit 1
fi

# Get current user/role name
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo "Current user/role: $CURRENT_USER"

# Attach AdministratorAccess policy
echo "🔗 Attaching AdministratorAccess policy..."
if [[ $CURRENT_USER == *"user"* ]]; then
    # It's a user
    aws iam attach-user-policy \
        --user-name $CURRENT_USER \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
    echo "✅ AdministratorAccess attached to user: $CURRENT_USER"
else
    # It's a role
    aws iam attach-role-policy \
        --role-name $CURRENT_USER \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
    echo "✅ AdministratorAccess attached to role: $CURRENT_USER"
fi

echo ""
echo "✅ AdministratorAccess granted successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Wait 5-10 minutes for IAM changes to propagate"
echo "2. Run: ./phase1-test.sh test dev"
echo "3. If successful, run: ./phase1-test.sh deploy dev"
echo ""
echo "⚠️  IMPORTANT: Remember to remove AdministratorAccess after testing!"
echo "   Run: ./remove-admin-access.sh" 