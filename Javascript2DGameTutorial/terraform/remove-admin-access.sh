#!/bin/bash

# Remove Admin Access Script
# This script removes AdministratorAccess policy after testing

set -e

echo "🔧 Removing AdministratorAccess policy..."

# Get current user/role name
CURRENT_USER=$(aws sts get-caller-identity --query 'Arn' --output text | cut -d'/' -f2)
echo "Current user/role: $CURRENT_USER"

# Remove AdministratorAccess policy
echo "🔗 Detaching AdministratorAccess policy..."
if [[ $CURRENT_USER == *"user"* ]]; then
    # It's a user
    aws iam detach-user-policy \
        --user-name $CURRENT_USER \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
    echo "✅ AdministratorAccess removed from user: $CURRENT_USER"
else
    # It's a role
    aws iam detach-role-policy \
        --role-name $CURRENT_USER \
        --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"
    echo "✅ AdministratorAccess removed from role: $CURRENT_USER"
fi

echo ""
echo "✅ AdministratorAccess removed successfully!"
echo "🔒 Your account is now secured again." 