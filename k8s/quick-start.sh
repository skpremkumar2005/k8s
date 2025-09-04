#!/bin/bash

# Quick Start Script for Local Kubernetes (Minikube)
# This script sets up everything needed to run the browser platform locally

set -e

echo "🚀 Quick Start: Browser Platform on Local Kubernetes"
echo "======================================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Step 1: Check/Install Minikube
print_step "Checking Minikube installation..."
if ! command -v minikube &> /dev/null; then
    print_info "Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    print_success "Minikube installed"
else
    print_success "Minikube already installed"
fi

# Step 2: Check/Install kubectl
print_step "Checking kubectl installation..."
if ! command -v kubectl &> /dev/null; then
    print_info "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    print_success "kubectl installed"
else
    print_success "kubectl already installed"
fi

# Step 3: Start Minikube
print_step "Starting Minikube cluster..."
if ! minikube status | grep -q "Running"; then
    minikube start --memory=8192 --cpus=4 --driver=docker
    print_success "Minikube started"
else
    print_success "Minikube already running"
fi

# Step 4: Enable Ingress
print_step "Enabling ingress addon..."
minikube addons enable ingress
print_success "Ingress enabled"

# Step 5: Deploy Browser Platform
print_step "Deploying Browser Platform..."
./deploy.sh
print_success "Browser Platform deployed"

# Step 6: Get access information
print_step "Getting access information..."
echo
echo "🎉 Setup Complete! Your Browser Platform is running on Kubernetes"
echo "================================================================"

# Wait for pods to be ready
kubectl wait --for=condition=available --timeout=300s deployment/browser-platform -n browser-platform

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "🌐 Minikube IP: $MINIKUBE_IP"

# Check if LoadBalancer is ready
print_info "Waiting for LoadBalancer to get external IP..."
sleep 10

# Get service information
kubectl get svc -n browser-platform

echo
echo "📋 Access Methods:"
echo "=================="
echo "1. 🔗 Port Forward (Recommended for testing):"
echo "   kubectl port-forward svc/browser-platform-service 8080:80 -n browser-platform"
echo "   Then access: http://localhost:8080"
echo
echo "2. 🌍 Minikube Service:"
echo "   minikube service browser-platform-loadbalancer -n browser-platform"
echo
echo "3. 🌐 Direct IP Access:"
echo "   Get NodePort: kubectl get svc browser-platform-loadbalancer -n browser-platform"
echo "   Access: http://$MINIKUBE_IP:NODEPORT"

echo
echo "📊 Useful Commands:"
echo "=================="
echo "• View pods: kubectl get pods -n browser-platform"
echo "• View logs: kubectl logs -f deployment/browser-platform -n browser-platform"
echo "• Scale app: kubectl scale deployment browser-platform --replicas=5 -n browser-platform"
echo "• Stop Minikube: minikube stop"
echo "• Delete everything: kubectl delete namespace browser-platform"

echo
print_success "🚀 Your Browser Platform is ready to use!"
