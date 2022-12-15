# In order to use the AKS Dapr extension, you must first enable the AKS-ExtensionManager and AKS-Dapr feature flags on your Azure subscription.
az feature register --namespace "Microsoft.ContainerService" --name "AKS-ExtensionManager"
az feature register --namespace "Microsoft.ContainerService" --name "AKS-Dapr"

# Confirm the registration status 
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-ExtensionManager')].{Name:name,State:properties.state}"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/AKS-Dapr')].{Name:name,State:properties.state}"

# Refresh the registration of the Microsoft.KubernetesConfiguration and Microsoft.ContainerService
az provider register --namespace Microsoft.KubernetesConfiguration
az provider register --namespace Microsoft.ContainerService

# Enable the Azure CLI extension for cluster extensions
az extension add --name k8s-extension
# or update it
az extension update --name k8s-extension

# Variables
RESOURCE_GROUP="aks-for-dapr"
LOCATION="northeurope"
AKS_NAME="dapr-demo"

# Create resource group
az group create -n $RESOURCE_GROUP -l $LOCATION

# Create cluster
az aks create --resource-group $RESOURCE_GROUP \
--name $AKS_NAME \
--node-count 2 \
--node-vm-size Standard_B4ms \
--generate-ssh-keys

# Get credentials
az aks get-credentials -n $AKS_NAME -g $RESOURCE_GROUP

# Create the extension and install Dapr on your AKS cluster
az k8s-extension create --cluster-type managedClusters \
--cluster-name $AKS_NAME \
--resource-group $RESOURCE_GROUP \
--name daprExtension \
--extension-type Microsoft.Dapr \
--auto-upgrade-minor-version true

# Check Dapr control plane
kubectl get pods -n dapr-system

# Deploy demo
NAMESPACE="tour-of-heroes"

kubectl create ns $NAMESPACE
kubectl apply -f dapr-k8s-manifests --recursive -n $NAMESPACE

# Check pods
watch kubectl get pods -n $NAMESPACE

# If your Dapr enabled apps are using components that fetch secrets from non-default namespaces, apply the following resources to that namespace:
kubectl create -f - <<EOF
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: $NAMESPACE
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
---

kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: dapr-secret-reader
  namespace: $NAMESPACE
subjects:
- kind: ServiceAccount
  name: default
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io

EOF

# Check pods again
watch kubectl get pods -n $NAMESPACE

# Check services
kubectl get svc -n $NAMESPACE

# Get public Ips
TOUR_OF_HEROES_PUBLIC_IP=$(kubectl get svc tour-of-heroes-api  -n $NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[0].ip}")
TOUR_OF_VILLAIN_PUBLIC_IP=$(kubectl get svc tour-of-villains-api  -n $NAMESPACE -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

# Variables for cURL commands
HERO_API_URL=http://$TOUR_OF_HEROES_PUBLIC_IP/api/hero
VILLAIN_API_URL=http://$TOUR_OF_VILLAIN_PUBLIC_IP/villain

# Check if hero api is working
curl $HERO_API_URL | jq

curl --header "Content-Type: application/json" \
  --request POST \
  --data '{
    "name": "Batman",
    "description": "Un multimillonario magnate empresarial y filántropo dueño de Empresas Wayne en Gotham City. Después de presenciar el asesinato de sus padres, el Dr. Thomas Wayne y Martha Wayne en un violento y fallido asalto cuando era niño, juró venganza contra los criminales, un juramento moderado por el sentido de la justicia.",
    "alterEgo": "Bruce Wayne" 
   
}' \
  $HERO_API_URL | jq

# Get heroes again
curl $HERO_API_URL | jq

# Check if villain api is working
curl --header "Content-Type: application/json" \
  --request POST \
  --data '{
    "name": "Octopus",
    "hero":{
        "name": "Spiderman",
        "description": "un joven huérfano neoyorquino que adquiere superpoderes después de ser mordido por una araña radiactiva, y cuya ideología como héroe se ve reflejada primordialmente en la expresión «un gran poder conlleva una gran responsabilidad».20​21​ Suele ser asociado con una personalidad bromista, amable, inventiva y optimista, lo que le ha llevado a ser catalogado como el «vecino amigable» de cualquiera lo cual, aunado a sus vivencias caracterizadas por los problemas cotidianos.",
        "alterEgo": "Peter Parker"     
    },
    "description": "Es un científico loco muy inteligente y algo fornido que tiene cuatro apéndices fuertes que se asemejan a los tentáculos de un pulpo, que se extienden desde la parte posterior de su cuerpo y pueden usarse para varios propósitos."
}' \
  $VILLAIN_API_URL | jq

# Check if pub sub is working viewing logs
kubectl logs -l app=tour-of-heroes-api -c tour-of-heroes-api -n $NAMESPACE

# Check if service to service invocation is working
curl $HERO_API_URL/villain/spiderman | jq

# Forward a port to Dapr dashboard
dapr dashboard -k -p 9999

# Access to zipkin to see traces
kubectl port-forward deployment/zipkin -n $NAMESPACE 9411:9411 
http://localhost:9411

