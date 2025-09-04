# 🚀 Kubernetes Deployment Guide for Browser Platform

## Prerequisites

### 1. Install Required Tools
```bash
# Install kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client
```

### 2. Set Up Kubernetes Cluster

#### Option A: Local Development (Minikube)
```bash
# Install Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start Minikube
minikube start --memory=8192 --cpus=4
minikube addons enable ingress
```

#### Option B: Cloud Kubernetes (GKE, EKS, AKS)
```bash
# Google Cloud (GKE)
gcloud container clusters create browser-platform-cluster \
  --num-nodes=3 \
  --machine-type=e2-standard-4 \
  --enable-autoscaling \
  --min-nodes=1 \
  --max-nodes=10

# AWS (EKS) - Install eksctl first
eksctl create cluster --name browser-platform --region us-west-2 --nodegroup-name standard-workers --node-type m5.large --nodes 3 --nodes-min 1 --nodes-max 10

# Azure (AKS)
az aks create --resource-group myResourceGroup --name browser-platform-cluster --node-count 3 --enable-addons monitoring --generate-ssh-keys
```

## Step-by-Step Deployment

### Step 1: Prepare Your Environment
```bash
# Clone and navigate to project
cd /path/to/your/browser_use_webrtc/unified-browser-platform

# Verify Docker image is available
docker pull premkumarsk2005/unified-browser-platform:latest
```

### Step 2: Configure Secrets (Important!)
Edit `k8s/secrets.yaml` and update with your actual API keys:
```bash
# Edit the secrets file
nano k8s/secrets.yaml

# Update these values:
# - AZURE_OPENAI_API_KEY: "your-actual-api-key"
# - GOOGLE_API_KEY: "your-actual-google-key"
# - Any other sensitive configuration
```

### Step 3: Deploy to Kubernetes
```bash
# Option A: Use the automated script (Recommended)
./k8s/deploy.sh

# Option B: Manual deployment
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secrets.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml  # If nginx ingress is available
```

### Step 4: Verify Deployment
```bash
# Check if pods are running
kubectl get pods -n browser-platform

# Check services
kubectl get svc -n browser-platform

# Check horizontal pod autoscaler
kubectl get hpa -n browser-platform

# View logs
kubectl logs -f deployment/browser-platform -n browser-platform
```

### Step 5: Access Your Application

#### Method 1: LoadBalancer (Cloud)
```bash
# Get external IP
kubectl get svc browser-platform-loadbalancer -n browser-platform

# Access via: http://EXTERNAL-IP
```

#### Method 2: Ingress (with domain)
```bash
# Check ingress
kubectl get ingress -n browser-platform

# Add to /etc/hosts (for local testing)
echo "INGRESS-IP browser-platform.local" >> /etc/hosts

# Access via: http://browser-platform.local
```

#### Method 3: Port Forwarding (Development)
```bash
# Forward port
kubectl port-forward svc/browser-platform-service 8080:80 -n browser-platform

# Access via: http://localhost:8080
```

## Scaling Your Application

### Manual Scaling
```bash
# Scale to 10 replicas
kubectl scale deployment browser-platform --replicas=10 -n browser-platform

# Check scaling
kubectl get pods -n browser-platform
```

### Auto-scaling (Already configured)
- **CPU-based**: Scales when CPU > 70%
- **Memory-based**: Scales when Memory > 80%
- **Min replicas**: 2
- **Max replicas**: 20

### Monitor Auto-scaling
```bash
# Watch HPA in real-time
kubectl get hpa -n browser-platform -w

# Generate load to test scaling
# (Run multiple browser automation requests)
```

## Monitoring and Troubleshooting

### View Logs
```bash
# All pods logs
kubectl logs -f deployment/browser-platform -n browser-platform

# Specific pod logs
kubectl logs -f POD-NAME -n browser-platform

# Previous container logs (if crashed)
kubectl logs POD-NAME --previous -n browser-platform
```

### Debug Pod Issues
```bash
# Describe pod for events
kubectl describe pod POD-NAME -n browser-platform

# Execute into running pod
kubectl exec -it POD-NAME -n browser-platform -- /bin/bash

# Check resource usage
kubectl top pods -n browser-platform
```

### Health Checks
```bash
# Check health endpoint
kubectl port-forward svc/browser-platform-service 8080:80 -n browser-platform
curl http://localhost:8080/health
```

## Configuration Management

### Update Environment Variables
```bash
# Edit configmap
kubectl edit configmap browser-platform-config -n browser-platform

# Edit secrets
kubectl edit secret llm-secrets -n browser-platform

# Restart deployment to apply changes
kubectl rollout restart deployment/browser-platform -n browser-platform
```

### Rolling Updates
```bash
# Update to new image version
kubectl set image deployment/browser-platform browser-platform=premkumarsk2005/unified-browser-platform:v2.0 -n browser-platform

# Check rollout status
kubectl rollout status deployment/browser-platform -n browser-platform

# Rollback if needed
kubectl rollout undo deployment/browser-platform -n browser-platform
```

## Resource Management

### View Resource Usage
```bash
# Pod resource usage
kubectl top pods -n browser-platform

# Node resource usage
kubectl top nodes

# Describe resource quotas
kubectl describe resourcequota -n browser-platform
```

### Adjust Resource Limits
Edit `k8s/deployment.yaml` and modify:
```yaml
resources:
  requests:
    memory: "2Gi"    # Increase if needed
    cpu: "1000m"     # Increase if needed
  limits:
    memory: "4Gi"    # Increase if needed
    cpu: "2000m"     # Increase if needed
```

## Clean Up

### Remove Everything
```bash
# Delete namespace (removes everything)
kubectl delete namespace browser-platform

# Or delete individual components
kubectl delete -f k8s/
```

### Partial Cleanup
```bash
# Scale down to 0 (but keep configuration)
kubectl scale deployment browser-platform --replicas=0 -n browser-platform

# Delete specific resources
kubectl delete deployment browser-platform -n browser-platform
kubectl delete service browser-platform-loadbalancer -n browser-platform
```

## Production Considerations

### Security
- Use proper RBAC (Role-Based Access Control)
- Enable network policies
- Use private container registries
- Regularly update container images
- Use secrets for sensitive data

### High Availability
- Run across multiple availability zones
- Use PodDisruptionBudgets
- Configure proper health checks
- Implement monitoring and alerting

### Performance
- Use node affinity for better placement
- Configure resource requests/limits appropriately
- Monitor and tune JVM/Node.js settings
- Use horizontal and vertical pod autoscaling

### Cost Optimization
- Use spot/preemptible instances where appropriate
- Configure appropriate resource requests
- Use cluster autoscaling
- Monitor and optimize resource usage

## Example Usage

Once deployed, you can access your browser platform at the configured endpoint and use it exactly like the Docker version, but with the benefits of:

- **Automatic scaling** based on demand
- **High availability** across multiple pods
- **Load balancing** across all instances
- **Zero-downtime deployments**
- **Centralized logging and monitoring**

Your browser automation requests will be automatically distributed across all available pods, providing better performance and reliability.

## Support

For issues or questions:
1. Check pod logs: `kubectl logs -f deployment/browser-platform -n browser-platform`
2. Verify configuration: `kubectl get configmap,secret -n browser-platform`
3. Check resource usage: `kubectl top pods -n browser-platform`
4. Review events: `kubectl get events -n browser-platform --sort-by='.firstTimestamp'`
