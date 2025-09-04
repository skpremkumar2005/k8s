# 🚀 Server Deployment Guide - Scale Your Browser Platform with Kubernetes

## Quick Server Setup (One Command)

If you're on your server and want to deploy immediately:

```bash
# Upload your k8s folder to your server, then run:
./k8s/server-deploy.sh
```

This script will:
1. ✅ Install kubectl and minikube
2. ✅ Start Kubernetes cluster
3. ✅ Deploy your browser platform
4. ✅ Configure auto-scaling (2-20 containers)
5. ✅ Give you access URLs

---

## Manual Server Setup Steps

### Step 1: Prepare Your Server

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker (if not installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install minikube (for single-node K8s)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

### Step 2: Start Kubernetes

```bash
# Start minikube with enough resources
minikube start --memory=8192 --cpus=4 --driver=docker

# Enable required addons
minikube addons enable ingress
minikube addons enable metrics-server
```

### Step 3: Deploy Your Platform

```bash
# Copy your k8s folder to server, then:
cd /path/to/your/k8s/folder

# Deploy everything
kubectl apply -f namespace.yaml
kubectl apply -f secrets.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml
```

### Step 4: Access Your Platform

```bash
# Method 1: Port forwarding (works from anywhere)
kubectl port-forward svc/browser-platform-service 8080:80 -n browser-platform
# Access: http://your-server-ip:8080

# Method 2: Get NodePort
kubectl get svc browser-platform-loadbalancer -n browser-platform
# Access: http://your-server-ip:NODEPORT

# Method 3: Minikube tunnel (if on server directly)
minikube service browser-platform-loadbalancer -n browser-platform
```

---

## Scaling Operations

### View Current Status
```bash
# See all running containers (pods)
kubectl get pods -n browser-platform

# Check auto-scaling status
kubectl get hpa -n browser-platform

# View resource usage
kubectl top pods -n browser-platform
```

### Manual Scaling
```bash
# Scale to specific number of containers
kubectl scale deployment browser-platform --replicas=5 -n browser-platform

# Scale to 10 containers
kubectl scale deployment browser-platform --replicas=10 -n browser-platform

# Scale back to 2 containers
kubectl scale deployment browser-platform --replicas=2 -n browser-platform
```

### Watch Auto-Scaling in Action
```bash
# Watch scaling happen in real-time
kubectl get hpa -n browser-platform -w

# Watch pods being created/destroyed
kubectl get pods -n browser-platform -w

# Generate load to trigger scaling (example)
# Make multiple browser automation requests to trigger CPU/memory usage
```

---

## Server Configuration

### Your Current Auto-Scaling Setup:
- **Minimum containers**: 2 (always running)
- **Maximum containers**: 20 (scales up to this)
- **CPU trigger**: Scales up when average CPU > 70%
- **Memory trigger**: Scales up when average Memory > 80%
- **Scale down**: Automatically reduces when load decreases

### Resource Limits per Container:
- **Memory**: 1GB request, 2GB limit
- **CPU**: 0.5 CPU request, 1 CPU limit

---

## Production Tips

### For High Traffic:
```bash
# Increase max replicas
kubectl patch hpa browser-platform-hpa -n browser-platform -p '{"spec":{"maxReplicas":50}}'

# Increase server resources
minikube stop
minikube start --memory=16384 --cpus=8
```

### For Cost Optimization:
```bash
# Reduce min replicas during low usage
kubectl patch hpa browser-platform-hpa -n browser-platform -p '{"spec":{"minReplicas":1}}'

# Set stricter resource limits
# Edit deployment.yaml and reduce memory/CPU limits
```

### Monitoring:
```bash
# View logs from all containers
kubectl logs -f deployment/browser-platform -n browser-platform

# View events
kubectl get events -n browser-platform --sort-by='.firstTimestamp'

# Resource usage
kubectl top nodes
kubectl top pods -n browser-platform
```

---

## Troubleshooting

### If containers keep crashing:
```bash
# Check logs
kubectl logs -f deployment/browser-platform -n browser-platform

# Check events
kubectl describe pod POD-NAME -n browser-platform

# Increase resource limits in deployment.yaml
```

### If auto-scaling isn't working:
```bash
# Check metrics server
kubectl get apiservice v1beta1.metrics.k8s.io -o yaml

# Check HPA status
kubectl describe hpa browser-platform-hpa -n browser-platform
```

### If can't access externally:
```bash
# Use port forwarding
kubectl port-forward svc/browser-platform-service 8080:80 -n browser-platform

# Or expose via NodePort
kubectl patch svc browser-platform-loadbalancer -n browser-platform -p '{"spec":{"type":"NodePort"}}'
```

---

## Example Usage After Deployment

Once deployed, your platform works exactly like before, but now:

1. **Single URL**: `http://your-server-ip:PORT`
2. **Auto-scaling**: Handles 1-1000+ users automatically
3. **High availability**: Failed containers restart automatically
4. **Load balancing**: Requests distributed across all containers

### Example API calls:
```bash
# Health check
curl http://your-server-ip:8080/health

# Browser automation (same as before)
curl -X POST http://your-server-ip:8080/api/browser-use/tasks \
  -H "Content-Type: application/json" \
  -d '{"task": "Navigate to YouTube and search for MrBeast"}'
```

**Result**: Kubernetes automatically routes your request to the least busy container! 🚀

---

## Ready to Deploy?

1. **Quick method**: Upload k8s folder to server and run `./k8s/server-deploy.sh`
2. **Manual method**: Follow the step-by-step guide above

Your browser platform will be production-ready with auto-scaling in minutes! 🎉
