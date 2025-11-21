#!/bin/bash

# Configuration
IMAGE_NAME="grid-tile-generator"
TAG="latest"
FULL_IMAGE="$IMAGE_NAME:$TAG"

# If you want to push to a registry, set this to your Docker Hub username or registry URL
# Example: REGISTRY="yourusername" (for Docker Hub)
# Example: REGISTRY="ghcr.io/yourusername" (for GitHub Container Registry)
REGISTRY="kaljo14"

if [ -n "$REGISTRY" ]; then
    FULL_IMAGE="$REGISTRY/$IMAGE_NAME:$TAG"
fi

echo "Building Grid Tile Generator image: $FULL_IMAGE"

# Build the image for ARM64 (Raspberry Pi)
docker buildx build --platform linux/arm64 -t $FULL_IMAGE .

# Check if build succeeded
if [ $? -ne 0 ]; then
    echo "Build failed."
    exit 1
fi

echo "✅ Build successful!"
echo ""

# Decide what to do next
if [ -n "$REGISTRY" ]; then
    echo "Pushing to registry: $REGISTRY"
    docker push $FULL_IMAGE
    if [ $? -eq 0 ]; then
        echo "✅ Push successful!"
    else
        echo "❌ Push failed. Make sure you're logged in: docker login"
        exit 1
    fi
else
    echo "No registry configured. Importing to k3s..."
    
    # Save the image to a tar file
    docker save $FULL_IMAGE -o /tmp/grid-generator.tar
    
    # Import into k3s
    sudo k3s ctr images import /tmp/grid-generator.tar
    
    if [ $? -eq 0 ]; then
        echo "✅ Image imported to k3s successfully!"
        rm /tmp/grid-generator.tar
    else
        echo "❌ Import failed. Make sure k3s is running."
        exit 1
    fi
fi

echo ""
echo "Next steps:"
echo "  1. Run the generator as a Kubernetes Job to create tiles"
echo "  2. Deploy the tileserver to serve the generated tiles"
