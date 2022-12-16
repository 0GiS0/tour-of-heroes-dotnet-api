# Install the Azure Container Apps extension for the CLI
az extension add --name containerapp --upgrade

# Register the Microsoft.App namespace.
az provider register --namespace Microsoft.App

# Register the Microsoft.OperationalInsights provider for the Azure Monitor Log Analytics workspace if you have not used it before.
az provider register --namespace Microsoft.OperationalInsights


# Variables
RESOURCE_GROUP="tour-of-heroes"
LOCATION="northeurope"
CONTAINERAPPS_ENVIRONMENT="heroes-and-villains-env"
VNET_NAME="tour-of-heroes-vnet"

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# https://learn.microsoft.com/en-us/azure/container-apps/vnet-custom-internal?tabs=bash&pivots=azure-cli
# Create vnet
az network vnet create \
  --resource-group $RESOURCE_GROUP \
  --name $VNET_NAME \
  --location $LOCATION \
  --address-prefix 10.0.0.0/16

# Network subnet address prefix requires a CIDR range of /23.
az network vnet subnet create \
  --resource-group $RESOURCE_GROUP \
  --vnet-name $VNET_NAME \
  --name infrastructure-subnet \
  --address-prefixes 10.0.0.0/23

INFRASTRUCTURE_SUBNET=`az network vnet subnet show --resource-group ${RESOURCE_GROUP} --vnet-name $VNET_NAME --name infrastructure-subnet --query "id" -o tsv | tr -d '[:space:]'`

# Create an environment
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" \
  --infrastructure-subnet-resource-id $INFRASTRUCTURE_SUBNET 

# Deploy services

#### Redis #####
REDIS_PASSWORD='passw0d!'
az containerapp create \
  --name redis \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image docker.io/redis:6.0.5 \
  --target-port 6379 \
  --ingress 'internal' \
  --transport tcp \
  --exposed-port 6379 \
  --min-replicas 1 \
  --max-replicas 1 \
  --args "--requirepass ${REDIS_PASSWORD}" \
  --cpu 0.25 --memory 0.5Gi

az containerapp delete \
  --name redis \
  --resource-group $RESOURCE_GROUP --yes

# https://learn.microsoft.com/en-us/azure/container-apps/connect-apps?tabs=bash
az containerapp show \
  --resource-group $RESOURCE_GROUP \
  --name redis \
  --query properties.configuration.ingress.fqdn

#### Zipkin #####
az containerapp create \
  --name zipkin \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image openzipkin/zipkin \
  --target-port 9411 \
  --ingress 'internal' \
  --min-replicas 1 \
  --max-replicas 1 \
  --env-vars STORAGE_TYPE="mem" \
  --cpu 0.25 --memory 0.5Gi

#### SQL Server #####
SA_PASSWORD='YourStrong!Passw0rd'
az containerapp create \
  --name tour-of-heroes-sql \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image mcr.microsoft.com/azure-sql-edge \
  --target-port 1433 \
  --ingress 'internal' \
  --transport tcp \
  --exposed-port 1433 \
  --min-replicas 1 \
  --max-replicas 1 \
  --env-vars ACCEPT_EULA="Y" SA_PASSWORD=${SA_PASSWORD} MSSQL_PID="Developer" \
  --cpu 1.25 --memory 2.5Gi 

  az containerapp show \
  --resource-group $RESOURCE_GROUP \
  --name tour-of-heroes-sql \
  --query properties.configuration.ingress.fqdn


# Configure the Dapr components in the Container Apps environment.
# https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cyaml#component-schema
### state store ###
az containerapp env dapr-component set \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name statestore \
    --yaml az-container-apps-dapr-components/statestore.yaml

az containerapp env dapr-component remove \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name statestore 

### secret store ###
### kubernetes secret store not supported
az containerapp env dapr-component set \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name secretstore \
    --yaml az-container-apps-dapr-components/secret-store.yaml

### pubsub ###
az containerapp env dapr-component set \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name pubsub \
    --yaml az-container-apps-dapr-components/publication.yaml

az containerapp env dapr-component remove \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name pubsub 

### subcription ### NOT SUPPORTED
# az containerapp env dapr-component set \
#     --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
#     --dapr-component-name pubsub \
#     --yaml az-container-apps-dapr-components/subscription.yaml

az containerapp env dapr-component list --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP -o table

  #### APIs with Dapr ####

  ### tour-of-heroes-api ###
  az containerapp create \
  --name tour-of-heroes-api \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image ghcr.io/0gis0/tour-of-heroes-dotnet-api/tour-of-heroes-api-dapr:2086efd \
  --target-port 5222 \
  --exposed-port 80 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 3 \
  --enable-dapr true \
  --dapr-app-id tour-of-heroes-api \
  --dapr-app-port  5222 \
  --dapr-log-level debug \
  --dapr-enable-api-logging \
  --cpu 0.25 --memory 0.5Gi 

az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-heroes-api --follow

  ### tour-of-villains-api ###
  az containerapp create \
  --name tour-of-villains-api \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image ghcr.io/0gis0/tour-of-villains-api/tour-of-villains-api-dapr:fce0c6d \
  --env-vars ConnectionStrings__DefaultConnection='Server=tour-of-heroes-sql.internal.calmbeach-9f999c94.northeurope.azurecontainerapps.io,1433;Initial Catalog=heroes;Persist Security Info=False;User ID=sa;Password=YourStrong!Passw0rd;' \
  --target-port 5111 \
  --exposed-port 9090 \
  --ingress 'external' \
  --min-replicas 1 \
  --max-replicas 3 \
  --enable-dapr true \
  --dapr-app-id tour-of-villains-api \
  --dapr-app-port  5111 \
  --dapr-log-level debug \
  --dapr-enable-api-logging \
  --cpu 0.25 --memory 0.5Gi

# See logs
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-villains-api --follow
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-villains-api --container daprd --follow
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-villains-api --type system --follow

  az containerapp delete \
  --name tour-of-villains-api \
  --resource-group $RESOURCE_GROUP 

# Using YAML file: https://learn.microsoft.com/en-us/azure/container-apps/azure-resource-manager-api-spec?tabs=yaml#container-app-examples

ContainerAppConsoleLogs_CL
| where RevisionName_s == "tour-of-villains-api--0htle0p"
| project Log_s 