#!/bin/bash

# Configuration variables
IMAGE_NAME="satellite-control-backend"
TAG="latest"
REGISTRY="yourusername"  # Replace with your Docker Hub username or registry (e.g., for AWS ECR)
PORT="8000"
ENV_FILE=".env"

# Exit on any error
set -e

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Error: Docker is not installed. Please install Docker and try again."
        exit 1
    fi
    echo "Docker is installed."
}

# Function to build the Docker image
build_image() {
    echo "Building Docker image: ${IMAGE_NAME}:${TAG}"
    docker build -t ${IMAGE_NAME}:${TAG} .
    echo "Docker image built successfully."
}

# Function to test the container locally
test_container() {
    echo "Running container locally on port ${PORT}"
    docker run -d -p ${PORT}:${PORT} --env-file ${ENV_FILE} --name ${IMAGE_NAME}-test ${IMAGE_NAME}:${TAG}
    sleep 5  # Wait for container to start

    # Test health endpoint
    echo "Testing health endpoint..."
    curl -s -o /dev/null -w "%{http_code}" http://localhost:${PORT}/health | grep -q 200 && echo "Health check passed!" || {
        echo "Health check failed!"
        docker logs ${IMAGE_NAME}-test
        docker stop ${IMAGE_NAME}-test
        docker rm ${IMAGE_NAME}-test
        exit 1
    }

    # Stop and remove test container
    echo "Stopping and removing test container..."
    docker stop ${IMAGE_NAME}-test
    docker rm ${IMAGE_NAME}-test
}

# Function to push to a container registry (optional)
push_image() {
    if [ -n "${REGISTRY}" ]; then
        echo "Tagging image for registry: ${REGISTRY}/${IMAGE_NAME}:${TAG}"
        docker tag ${IMAGE_NAME}:${TAG} ${REGISTRY}/${IMAGE_NAME}:${TAG}

        echo "Pushing image to registry..."
        docker push ${REGISTRY}/${IMAGE_NAME}:${TAG}
        echo "Image pushed successfully."
    else
        echo "No registry specified, skipping push."
    fi
}

# Function to run the container in production mode
run_container() {
    echo "Running container in production mode..."
    docker run -d -p ${PORT}:${PORT} --env-file ${ENV_FILE} --name ${IMAGE_NAME} ${IMAGE_NAME}:${TAG}
    echo "Container is running. Access at http://localhost:${PORT}"
}

# Main execution
echo "Starting deployment process..."
check_docker
build_image
test_container

# Uncomment the following line to enable pushing to a registry
# push_image

# Run the container (remove this if deploying to a cloud service like ECS/Kubernetes)
run_container

echo "Deployment completed successfully!"