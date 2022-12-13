# Create k8s cluster for dapr
kind create cluster --name dapr-k8s --config kind-cluster-config.yaml

# Initialice dapr
dapr init --kubernetes

# Verify 
dapr status -k

# Forward a port to Dapr dashboard
dapr dashboard -k -p 9999

# Deploy tour-of-heroes 
kubectl apply dapr-k8s-manifests --recursive