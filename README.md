# Online Boutique - Cloud Computing Project

Microservices demo application deployed on Google Kubernetes Engine (GKE) with monitoring.

## Deployment steps

### Prerequisites
- Google Cloud Platform account with billing enabled
- `gcloud` CLI configured
- `kubectl` installed
- `helm` installed

### 1. Create GKE Cluster

```bash
gcloud container clusters create online-boutique-cluster \
  --zone=europe-west9-b \
  --num-nodes=4 \
  --machine-type=e2-medium

gcloud container clusters get-credentials online-boutique-cluster --zone=europe-west9-b
```

### 2. Deploy Online Boutique Application

```bash
kubectl apply -k kustomize/custom-deployment/
```

**Access the application:**
```bash
kubectl get service frontend-external
# Visit http://<EXTERNAL-IP>
```

### 3. Deploy Monitoring Stack Optionally

```bash
# Add Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create namespace
kubectl create namespace monitoring

# Deploy Prometheus + Grafana
helm install prometheus-stack prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values monitoring-values.yaml
```

**Access Grafana:**
```bash
kubectl get svc -n monitoring prometheus-stack-grafana
# Visit http://<EXTERNAL-IP>
# Login: admin / admin.123
```

**Check pre-configured dashboards:**
- Kubernetes / Compute Resources / Node (Pods) - node-level metrics
- Kubernetes / Compute Resources / Pod - pod-level metrics
- Node Exporter / Nodes - detailed node metrics

### 4. Cleanup

You can run the cleanup script when you are finished working with the cluster:

```bash
./cleanup-gcp.sh
```
You will have to reply to prompts (y/n) confirming the deletion of resources. \
You will need to wait until you see `=== Cleanup Complete ===` message which indicates that the cleanup process finished.

## Project Structure

### Resource Optimization with Kustomize
- **Code**: `kustomize/custom-deployment/`
  - `kustomization.yaml` - overlay configuration
  - `reduce-resources.yaml` - CPU/memory adjustments
- **Changes**: Reduced resource requests to fit 3-node cluster

### Monitoring Stack
- **Code**: `monitoring/monitoring-values.yaml`
- **Components**: Prometheus, Grafana, Node Exporter, cAdvisor
- **Changes**: Added monitoring services to the cluster.

### Automation Scripts
- **Code**: `scripts/cleanup-gcp.sh`
- **Changes**: Help with automated cleanup of GCP resources

## Resource Requirements

- **Application only**: 3 nodes (e2-medium)
- **Application + Monitoring**: 4 nodes (e2-medium)


## Key Configuration Files

| File | Purpose |
|------|---------|
| `kustomize/custom-deployment/kustomization.yaml` | Kustomize overlay configuration |
| `kustomize/custom-deployment/reduce-resource.yaml` | Resource optimization patches |
| `monitoring/monitoring-values.yaml` | Monitoring stack configuration |
| `scripts/cleanup-gcp.sh` | Automated cleanup script |

## Troubleshooting

**Pods pending due to insufficient CPU:**
```bash
# Scale cluster
gcloud container clusters resize online-boutique-cluster \
  --num-nodes=4 \
  --zone=europe-west9-b
```

**Monitoring dashboards not loading:**
- Verify Prometheus pod is running: `kubectl get pods -n monitoring`
- Check it shows `2/2` ready status
