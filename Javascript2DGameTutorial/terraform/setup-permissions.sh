#!/bin/bash

# Setup AWS Permissions for EKS Deployment
# This script helps set up the required IAM permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  AWS Permissions Setup${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check AWS CLI
check_aws_cli() {
    print_info "Checking AWS CLI..."
    
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI not found. Please install it first."
        exit 1
    fi
    
    if ! aws sts get-caller-identity > /dev/null 2>&1; then
        print_error "AWS CLI not configured. Please run 'aws configure'"
        exit 1
    fi
    
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    
    print_success "AWS configured for account: $AWS_ACCOUNT in region: $AWS_REGION"
}

# Function to create IAM policy
create_iam_policy() {
    print_info "Creating IAM policy for EKS permissions..."
    
    POLICY_NAME="EKSFullAccessPolicy"
    
    # Check if policy already exists
    if aws iam get-policy --policy-arn "arn:aws:iam::${AWS_ACCOUNT}:policy/${POLICY_NAME}" > /dev/null 2>&1; then
        print_warning "Policy ${POLICY_NAME} already exists"
        return 0
    fi
    
    # Create policy from JSON file
    if [ -f "iam-policy.json" ]; then
        aws iam create-policy \
            --policy-name "${POLICY_NAME}" \
            --policy-document file://iam-policy.json \
            --description "Full access policy for EKS cluster management"
        
        print_success "IAM policy ${POLICY_NAME} created successfully"
    else
        print_error "iam-policy.json file not found"
        exit 1
    fi
}

# Function to attach policy to current user
attach_policy_to_user() {
    print_info "Attaching policy to current user..."
    
    POLICY_NAME="EKSFullAccessPolicy"
    CURRENT_USER=$(aws sts get-caller-identity --query Arn --output text | cut -d'/' -f2)
    
    # Check if user already has the policy
    if aws iam list-attached-user-policies --user-name "${CURRENT_USER}" --query "AttachedPolicies[?PolicyName=='${POLICY_NAME}'].PolicyName" --output text | grep -q "${POLICY_NAME}"; then
        print_warning "Policy ${POLICY_NAME} is already attached to user ${CURRENT_USER}"
        return 0
    fi
    
    # Attach policy to user
    aws iam attach-user-policy \
        --user-name "${CURRENT_USER}" \
        --policy-arn "arn:aws:iam::${AWS_ACCOUNT}:policy/${POLICY_NAME}"
    
    print_success "Policy ${POLICY_NAME} attached to user ${CURRENT_USER}"
}

# Function to create service-linked roles
create_service_linked_roles() {
    print_info "Creating service-linked roles..."
    
    # Create EKS service-linked role
    if ! aws iam get-role --role-name "AWSServiceRoleForAmazonEKS" > /dev/null 2>&1; then
        aws iam create-service-linked-role --aws-service-name eks.amazonaws.com
        print_success "EKS service-linked role created"
    else
        print_warning "EKS service-linked role already exists"
    fi
    
    # Create EC2 scheduled service-linked role
    if ! aws iam get-role --role-name "AWSServiceRoleForEC2ScheduledInstances" > /dev/null 2>&1; then
        aws iam create-service-linked-role --aws-service-name ec2scheduled.amazonaws.com
        print_success "EC2 scheduled service-linked role created"
    else
        print_warning "EC2 scheduled service-linked role already exists"
    fi
}

# Function to verify permissions
verify_permissions() {
    print_info "Verifying permissions..."
    
    # Test EKS permissions
    if aws eks list-clusters > /dev/null 2>&1; then
        print_success "EKS permissions verified"
    else
        print_warning "EKS permissions may be limited"
    fi
    
    # Test EC2 permissions
    if aws ec2 describe-instances --max-items 1 > /dev/null 2>&1; then
        print_success "EC2 permissions verified"
    else
        print_warning "EC2 permissions may be limited"
    fi
    
    # Test IAM permissions
    if aws iam list-roles --max-items 1 > /dev/null 2>&1; then
        print_success "IAM permissions verified"
    else
        print_warning "IAM permissions may be limited"
    fi
}

# Function to show next steps
show_next_steps() {
    print_header
    echo ""
    print_info "Next steps:"
    echo "1. Wait a few minutes for IAM changes to propagate"
    echo "2. Run: cd terraform && ./phase1-test.sh test dev"
    echo "3. If you still get permission errors, contact your AWS administrator"
    echo ""
    print_warning "Note: IAM changes can take up to 5 minutes to propagate"
}

# Main function
main() {
    print_header
    
    check_aws_cli
    create_iam_policy
    attach_policy_to_user
    create_service_linked_roles
    verify_permissions
    show_next_steps
}

# Run main function
main "$@" 