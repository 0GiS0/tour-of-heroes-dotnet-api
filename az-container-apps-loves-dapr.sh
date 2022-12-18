# Install the Azure Container Apps extension for the CLI
az extension add --name containerapp --upgrade

# Register the Microsoft.App namespace.
az provider register --namespace Microsoft.App

# Register the Microsoft.OperationalInsights provider for the Azure Monitor Log Analytics workspace if you have not used it before.
az provider register --namespace Microsoft.OperationalInsights

# Variables
RESOURCE_GROUP="tour-of-heroes-capps"
LOCATION="northeurope"
CONTAINERAPPS_ENVIRONMENT="heroes-and-villains-env"
VNET_NAME="capps-vnet"

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# https://learn.microsoft.com/en-us/azure/container-apps/vnet-custom-internal?tabs=bash&pivots=azure-cli
# Create vnet
# az network vnet create \
#   --resource-group $RESOURCE_GROUP \
#   --name $VNET_NAME \
#   --location $LOCATION \
#   --address-prefix 10.0.0.0/16

# # Network subnet address prefix requires a CIDR range of /23.
# az network vnet subnet create \
#   --resource-group $RESOURCE_GROUP \
#   --vnet-name $VNET_NAME \
#   --name infrastructure-subnet \
#   --address-prefixes 10.0.0.0/23

# INFRASTRUCTURE_SUBNET=$(az network vnet subnet show --resource-group ${RESOURCE_GROUP} --vnet-name $VNET_NAME --name infrastructure-subnet --query "id" -o tsv | tr -d '[:space:]')

# Create an environment
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" 
  # --infrastructure-subnet-resource-id $INFRASTRUCTURE_SUBNET \
  # --debug

# Deploy services

#### Redis #####
# REDIS_PASSWORD='passw0rd!'
# az containerapp create \
#   --name redisdb \
#   --resource-group $RESOURCE_GROUP \
#   --environment $CONTAINERAPPS_ENVIRONMENT \
#   --image docker.io/redis:7.0 \
#   --target-port 6379 \
#   --exposed-port 20305 \
#   --ingress 'external' \
#   --transport tcp \
#   --cpu 0.25 --memory 0.5Gi

# az containerapp logs show --resource-group $RESOURCE_GROUP -n redisdb --container redisdb

# # With TCP ingress enabled, your container app features the following characteristics:

# # The container app is accessed via its fully qualified domain name (FQDN) and exposed port number
# # Other container apps in the same environment can also access a TCP ingress-enabled container app by using its name (defined by the name property in the Container Apps resource) and exposed port number

# # https://github.com/microsoft/azure-container-apps/issues/375

# # Create client for that redis to test it
# az containerapp create \
#   --name redis-client \
#   --resource-group $RESOURCE_GROUP \
#   --environment $CONTAINERAPPS_ENVIRONMENT \
#   --image docker.io/redis:7.0 
  
# az containerapp logs show --resource-group $RESOURCE_GROUP -n redis-client  --container redis-client --follow

# az containerapp exec --name redis-client -g $RESOURCE_GROUP 

# # Commands inside container
# redis-cli -h redisdb -p 20305
# SET mykey "Hello\nWorld"
# GET mykey


# az containerapp delete \
#   --name redis-client \
#   --resource-group $RESOURCE_GROUP --yes

# az containerapp delete \
#   --name redis \
#   --resource-group $RESOURCE_GROUP --yes


# # https://learn.microsoft.com/en-us/azure/container-apps/connect-apps?tabs=bash
# az containerapp show \
#   --resource-group $RESOURCE_GROUP \
#   --name redis \
#   --query properties.configuration.ingress.fqdn

# #### Zipkin #####
# az containerapp create \
#   --name zipkin \
#   --resource-group $RESOURCE_GROUP \
#   --environment $CONTAINERAPPS_ENVIRONMENT \
#   --image openzipkin/zipkin \
#   --target-port 9411 \
#   --ingress 'internal' \
#   --min-replicas 1 \
#   --max-replicas 1 \
#   --env-vars STORAGE_TYPE="mem" \
#   --cpu 0.25 --memory 0.5Gi

# #### SQL Server #####
# SA_PASSWORD='YourStrong!Passw0rd'
# az containerapp create \
#   --name tour-of-heroes-sql \
#   --resource-group $RESOURCE_GROUP \
#   --environment $CONTAINERAPPS_ENVIRONMENT \
#   --image mcr.microsoft.com/mssql/server:latest \
#   --target-port 1433 \
#   --ingress 'internal' \
#   --transport tcp \  
#   --min-replicas 1 \
#   --max-replicas 1 \
#   --env-vars ACCEPT_EULA="Y" SA_PASSWORD=${SA_PASSWORD} MSSQL_PID="Developer" \
#   --cpu 1.25 --memory 2.5Gi 

# az containerapp delete \
# --name tour-of-heroes-sql \
# --resource-group $RESOURCE_GROUP --yes

# SQL_FQDN=$(az containerapp show \
#   --resource-group $RESOURCE_GROUP \
#   --name tour-of-heroes-sql \
#   --query properties.configuration.ingress.fqdn)

# Redis
REDIS_NAME="redis-cache-for-capps"
# Dapr can use any Redis instance - containerized, running on your local dev machine, or a managed cloud service, provided the version of Redis is 5.0.0 or later.
az redis create --location $LOCATION --name $REDIS_NAME --resource-group $RESOURCE_GROUP --sku Basic --vm-size c0 --redis-version 6 --enable-non-ssl-port 
REDIS_HOSTNAME=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query "hostName" -o tsv)
REDIS_ACCESS_KEY=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP --query "primaryKey" -o tsv)
az redis delete --name $REDIS_NAME --resource-group $RESOURCE_GROUP --yes

# SQL Server
SQL_SERVER_NAME="sqlserver-for-capps"
SQL_SERVER_USER="usersql"
SQL_SERVER_PASSWORD="p@ssw0rd"
startIp='0.0.0.0'
endIp='0.0.0.0'
az sql server create --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP --location "$LOCATION" --admin-user $SQL_SERVER_USER --admin-password $SQL_SERVER_PASSWORD
az sql server firewall-rule create --resource-group $RESOURCE_GROUP --server $SQL_SERVER_NAME -n AllowYourIp --start-ip-address $startIp --end-ip-address $endIp
SQL_FQDN=$(az sql server show --name $SQL_SERVER_NAME --resource-group $RESOURCE_GROUP --query "fullyQualifiedDomainName" -o tsv)

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

### tour-of-villains-api ###
az containerapp create \
  --name tour-of-villains-api \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image ghcr.io/0gis0/tour-of-villains-api/tour-of-villains-api-dapr:bd00533 \
  --env-vars ConnectionStrings__DefaultConnection="Server=${SQL_FQDN},1433;Initial Catalog=heroes;Persist Security Info=False;User ID=${SQL_SERVER_USER};Password=${SQL_SERVER_PASSWORD};" \
  --target-port 5111 \
  --ingress 'external' \
  --enable-dapr true \
  --dapr-app-id tour-of-villains-api \
  --dapr-app-port  5111 \
  --dapr-log-level debug \
  --dapr-enable-api-logging \
  --cpu 0.25 --memory 0.5Gi \
  --query configuration.ingress.fqdn

az containerapp browse -n tour-of-villains-api -g $RESOURCE_GROUP

# az containerapp delete \
# --name tour-of-villains-api \
# --resource-group $RESOURCE_GROUP --yes

# See logs
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-villains-api --follow
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-villains-api --container daprd --follow
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-villains-api --container tour-of-villains-api --follow
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-villains-api --type system --follow

  
  ### tour-of-heroes-api ###
  az containerapp create \
  --name tour-of-heroes-api \
  --resource-group $RESOURCE_GROUP \
  --environment $CONTAINERAPPS_ENVIRONMENT \
  --image ghcr.io/0gis0/tour-of-heroes-dotnet-api/tour-of-heroes-api-dapr:1b49d7b \
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

az containerapp secret set  \
-n tour-of-heroes-api -g $RESOURCE_GROUP \
--secrets sql-connection="Server=${SQL_FQDN},1433;Initial Catalog=heroes;Persist Security Info=False;User ID=${SQL_SERVER_USER};Password=${SQL_SERVER_PASSWORD};"

az containerapp browse -n tour-of-heroes-api -g $RESOURCE_GROUP

az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-heroes-api --follow


# Using YAML file: https://learn.microsoft.com/en-us/azure/container-apps/azure-resource-manager-api-spec?tabs=yaml#container-app-examples

ContainerAppConsoleLogs_CL
| where ContainerAppName_s == "tour-of-heroes-api"
| project Log_s

LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az containerapp env show --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --query properties.appLogsConfiguration.logAnalyticsConfiguration.customerId --out tsv`

az monitor log-analytics query \
  --workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
  --analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'queuereader' and Log_s contains 'Message ID' | project Time=TimeGenerated, AppName=ContainerAppName_s, Revision=RevisionName_s, Container=ContainerName_s, Message=Log_s | take 5" \
  --out table

ContainerAppSystemLogs_CL
| where RevisionName_s == <revision-name>
| where Type_s != "Normal"
| project Log_s


az group delete -n $RESOURCE_GROUP -y --no-wait

# https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cyaml#unsupported-dapr-capabilities