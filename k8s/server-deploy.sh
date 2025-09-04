#!/bin/bash

# Server Deployment Script for Browser Platform on Kubernetes
# This script deploys your existing Docker image to a server with Kubernetes

set -e

echo "🚀 Deploying Browser Platform to Server with Kubernetes..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
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

# Check if running on server
if [[ $(hostname) != *"server"* ]] && [[ $(hostname) != *"ubuntu"* ]]; then
    read -p "⚠️  This doesn't look like a server. Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi
fi

# Check prerequisites
print_status "Checking prerequisites..."

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    print_success "kubectl installed"
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    echo "Run: curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh"
    exit 1
fi

# Check if user can run docker
if ! docker ps &> /dev/null; then
    print_error "Cannot run Docker commands. Please add user to docker group:"
    echo "sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

# Check if minikube is installed (for local K8s)
if ! command -v minikube &> /dev/null; then
    print_status "Installing Minikube for local Kubernetes..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    print_success "Minikube installed"
fi

# Start Minikube if not running
print_status "Starting Kubernetes cluster..."
if ! minikube status | grep -q "Running"; then
    print_status "Starting Minikube with optimal settings for browser platform..."
    minikube start --memory=8192 --cpus=4 --driver=docker
    print_success "Minikube started"
else
    print_success "Minikube already running"
fi

# Enable ingress
print_status "Enabling ingress addon..."
minikube addons enable ingress
minikube addons enable metrics-server
print_success "Addons enabled"

# Pull your Docker image (in case it's not available locally)
print_status "Pulling your Docker image..."
docker pull premkumarsk2005/unified-browser-platform:latest
print_success "Docker image ready"

# Deploy to Kubernetes
print_status "Deploying to Kubernetes..."

# Create namespace
kubectl apply -f k8s/namespace.yaml
print_success "Namespace created"

# Deploy secrets and config
kubectl apply -f k8s/secrets.yaml
print_success "Secrets deployed"

# Deploy application
kubectl apply -f k8s/deployment.yaml
print_success "Application deployed"

# Deploy services
kubectl apply -f k8s/service.yaml
print_success "Services created"

# Deploy auto-scaler
kubectl apply -f k8s/hpa.yaml
print_success "Auto-scaler configured"

# Deploy ingress if available
if kubectl get ingressclass nginx &> /dev/null; then
    kubectl apply -f k8s/ingress.yaml
    print_success "Ingress deployed"
fi

# Wait for deployment
print_status "Waiting for pods to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/browser-platform -n browser-platform

# Show status
print_status "Deployment Status:"
kubectl get pods -n browser-platform -o wide

print_status "Services:"
kubectl get svc -n browser-platform

print_status "Auto-scaler:"
kubectl get hpa -n browser-platform

# Get access information
print_success "🎉 Deployment completed successfully!"
echo
echo "📋 Access Your Browser Platform:"
echo "================================"

# Method 1: Port forwarding (always works)
echo "🔗 Method 1: Port Forwarding (Recommended)"
echo "   Run: kubectl port-forward svc/browser-platform-service 8080:80 -n browser-platform"
echo "   Then access: http://localhost:8080"
echo

# Method 2: Minikube service
echo "🌐 Method 2: Minikube Service"
echo "   Run: minikube service browser-platform-loadbalancer -n browser-platform"
echo "   This will open browser automatically"
echo

# Method 3: Direct NodePort access
NODEPORT=$(kubectl get svc browser-platform-loadbalancer -n browser-platform -o jsonpath='{.spec.ports[0].nodePort}' 2>/dev/null || echo "pending")
MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "pending")
echo "🌍 Method 3: Direct Access"
echo "   IP: $MINIKUBE_IP"
echo "   Port: $NODEPORT"
if [[ "$NODEPORT" != "pending" && "$MINIKUBE_IP" != "pending" ]]; then
    echo "   URL: http://$MINIKUBE_IP:$NODEPORT"
fi
echo

echo "📊 Scaling Commands:"
echo "==================="
echo "• Scale manually: kubectl scale deployment browser-platform --replicas=10 -n browser-platform"
echo "• Watch auto-scaling: kubectl get hpa -n browser-platform -w"
echo "• View logs: kubectl logs -f deployment/browser-platform -n browser-platform"
echo "• View pods: kubectl get pods -n browser-platform"
echo

echo "🔄 Auto-Scaling is Active:"
echo "========================="
echo "• Minimum replicas: 2"
echo "• Maximum replicas: 20"
echo "• Scales up when CPU > 70% or Memory > 80%"
echo "• Scales down automatically when load decreases"
echo

print_success "🚀 Your browser platform is now running with Kubernetes auto-scaling!"
echo
echo "💡 Tips:"
echo "  - The platform will automatically scale based on usage"
echo "  - Failed containers will restart automatically"
echo "  - All traffic is load-balanced across all running containers"
echo "  - Use 'kubectl get pods -n browser-platform -w' to watch scaling in real-time"
