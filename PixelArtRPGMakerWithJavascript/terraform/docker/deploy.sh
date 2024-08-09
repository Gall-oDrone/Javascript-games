# Build the Docker image
docker build -t my-web-app -f deployment/dockerfile .

# Tag the image for ECR
docker tag my-web-app:latest ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/my-web-app:latest

# Authenticate Docker with your ECR registry
aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com

# Push the Docker image to ECR
docker push ${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/my-web-app:latest
