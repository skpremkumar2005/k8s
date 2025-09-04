#!/bin/bash

# Kubernetes Deployment Script for Browser Platform
# This script deploys the unified browser platform to Kubernetes

set -e

echo "🚀 Starting Kubernetes deployment for Browser Platform..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

print_success "Connected to Kubernetes cluster"

# Get current context
CURRENT_CONTEXT=$(kubectl config current-context)
print_status "Current context: $CURRENT_CONTEXT"

# Confirm deployment
read -p "Do you want to deploy to this cluster? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    print_warning "Deployment cancelled"
    exit 0
fi

# Deploy namespace
print_status "Creating namespace and resource quota..."
kubectl apply -f k8s/namespace.yaml
print_success "Namespace created"

# Deploy secrets and configmaps
print_status "Deploying secrets and configuration..."
kubectl apply -f k8s/secrets.yaml
print_success "Secrets and ConfigMaps deployed"

# Deploy application
print_status "Deploying browser platform application..."
kubectl apply -f k8s/deployment.yaml
print_success "Deployment created"

# Deploy services
print_status "Creating services..."
kubectl apply -f k8s/service.yaml
print_success "Services created"

# Deploy HPA
print_status "Setting up auto-scaling..."
kubectl apply -f k8s/hpa.yaml
print_success "Horizontal Pod Autoscaler configured"

# Check if nginx ingress controller is available
if kubectl get ingressclass nginx &> /dev/null; then
    print_status "Deploying ingress..."
    kubectl apply -f k8s/ingress.yaml
    print_success "Ingress deployed"
else
    print_warning "Nginx ingress controller not found. Skipping ingress deployment."
    print_warning "You can access the service via LoadBalancer or NodePort"
fi

# Wait for deployment to be ready
print_status "Waiting for deployment to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/browser-platform -n browser-platform

# Get deployment status
print_status "Checking deployment status..."
kubectl get pods -n browser-platform -o wide

print_status "Getting service information..."
kubectl get svc -n browser-platform

# Get access information
print_success "🎉 Deployment completed successfully!"
echo
echo "📋 Access Information:"
echo "===================="

# Check for LoadBalancer
LB_IP=$(kubectl get svc browser-platform-loadbalancer -n browser-platform -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
LB_HOSTNAME=$(kubectl get svc browser-platform-loadbalancer -n browser-platform -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [[ -n "$LB_IP" ]]; then
    echo "🌐 LoadBalancer IP: http://$LB_IP"
elif [[ -n "$LB_HOSTNAME" ]]; then
    echo "🌐 LoadBalancer: http://$LB_HOSTNAME"
else
    echo "⏳ LoadBalancer IP pending... Check with: kubectl get svc -n browser-platform"
fi

# Check for ingress
if kubectl get ingress browser-platform-ingress -n browser-platform &> /dev/null; then
    INGRESS_HOST=$(kubectl get ingress browser-platform-ingress -n browser-platform -o jsonpath='{.spec.rules[0].host}')
    echo "🌍 Ingress: http://$INGRESS_HOST"
    echo "   (Add '$INGRESS_HOST' to your /etc/hosts file pointing to your ingress controller IP)"
fi

# Port forwarding option
echo "🔗 Port forwarding: kubectl port-forward svc/browser-platform-service 8080:80 -n browser-platform"
echo "   Then access: http://localhost:8080"

echo
echo "📊 Monitoring Commands:"
echo "======================"
echo "• View pods: kubectl get pods -n browser-platform"
echo "• View logs: kubectl logs -f deployment/browser-platform -n browser-platform"
echo "• View HPA: kubectl get hpa -n browser-platform"
echo "• Scale manually: kubectl scale deployment browser-platform --replicas=5 -n browser-platform"

echo
print_success "Browser Platform is now running on Kubernetes! 🚀"
