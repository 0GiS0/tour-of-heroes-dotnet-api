# Create k8s cluster for dapr
kind create cluster --name dapr-k8s --config kind-cluster-config.yaml

# Initialice dapr
dapr init --kubernetes --wait

# Verify 
dapr status -k

# Forward a port to Dapr dashboard
dapr dashboard -k -p 9999

# Deploy tour-of-heroes 
kubectl apply -f dapr-k8s-manifests --recursive

# Check deployments
kubectl get deploy
k get pods -w

# Delete cluster
kind delete cluster --name dapr-k8s