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

# Create an environment
az containerapp env create \
  --name $CONTAINERAPPS_ENVIRONMENT \
  --resource-group $RESOURCE_GROUP \
  --location "$LOCATION" 


#######################
### Deploy services ###
#######################


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

# Azure key vault
KEY_VAULT_NAME="key-vault-for-capps"

# Generating a new Azure AD application and Service Principal 
# https://docs.dapr.io/developing-applications/integrations/azure/authenticating-azure/
APP_NAME="ad-app-for-capps"
# Create the app
APP_ID=$(az ad app create --display-name "${APP_NAME}"  | jq -r .appId)

# To create a client secret
CLIENT_SECRET=$(az ad app credential reset --id "${APP_ID}" --years 2 | jq -r .password)

# Create a service principal
SERVICE_PRINCIPAL_ID=$(az ad sp create --id "${APP_ID}" | jq -r .id)

# Create keyvault 
az keyvault create \
--name $KEY_VAULT_NAME \
--resource-group $RESOURCE_GROUP \
--location $LOCATION \
--enable-rbac-authorization true

# Assign reader role
RESOURCE_GROUP_ID=$(az group show -n $RESOURCE_GROUP --query id -o tsv)
az role assignment create \
  --assignee "${SERVICE_PRINCIPAL_ID}" \
  --role "Key Vault Secrets User" \
  --scope "${RESOURCE_GROUP_ID}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT_NAME}"

# Role assigment for Azure CLI
az role assignment create \
  --assignee $(az ad signed-in-user show --query id -o tsv) \
  --role "Key Vault Secrets Officer" \
  --scope "${RESOURCE_GROUP_ID}/providers/Microsoft.KeyVault/vaults/${KEY_VAULT_NAME}"
  
# Add new secret to the az key vault
az keyvault secret set -n sql-connection-string \
--value "Server=${SQL_FQDN},1433;Initial Catalog=heroes;Persist Security Info=False;User ID=${SQL_SERVER_USER};Password=${SQL_SERVER_PASSWORD};" \
--vault-name $KEY_VAULT_NAME

# Configure the Dapr components in the Container Apps environment.
# https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cyaml#component-schema

### state store ###
cat > az-container-apps-dapr-components/statestore.yaml <<EOF
version: v1
componentType: state.redis
metadata:
  - name: redisHost
    value: ${REDIS_NAME}.redis.cache.windows.net:6379
  - name: redisPassword
    value: "${REDIS_ACCESS_KEY}"
  - name: actorStateStore
    value: "true"
scopes:
- tour-of-heroes-api
EOF

az containerapp env dapr-component set \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name statestore \
    --yaml az-container-apps-dapr-components/statestore.yaml

az containerapp env dapr-component remove \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name statestore 

### secret store ###
### kubernetes secret store not supported

TENANT_ID=$(az account show --query tenantId -o tsv)

cat > az-container-apps-dapr-components/secret-store.yaml <<EOF
version: v1
componentType: secretstores.azure.keyvault
metadata:
  - name: vaultName
    value: "${KEY_VAULT_NAME}"
  - name: azureTenantId
    value: "${TENANT_ID}"
  - name: azureClientId
    value: "${APP_ID}"
  - name: azureClientSecret
    value: "$CLIENT_SECRET"
scopes:
- tour-of-heroes-api
EOF

az containerapp env dapr-component set \
    --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP \
    --dapr-component-name heroessecretstore \
    --yaml az-container-apps-dapr-components/secret-store.yaml

### pubsub ###

cat > az-container-apps-dapr-components/publication.yaml <<EOF
version: v1
componentType: pubsub.redis
metadata:
  - name: redisHost
    value: ${REDIS_NAME}.redis.cache.windows.net:6379
  - name: redisPassword
    value: "${REDIS_ACCESS_KEY}"
EOF

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
az containerapp env dapr-component show  --dapr-component-name secretstore --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP -o yaml

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
  --image ghcr.io/0gis0/tour-of-heroes-dotnet-api/tour-of-heroes-api-dapr:bf1be45 \
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

az containerapp browse -n tour-of-heroes-api -g $RESOURCE_GROUP

az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-heroes-api --container daprd --follow
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-heroes-api --container tour-of-heroes-api --follow

az containerapp delete \
--name tour-of-heroes-api \
--resource-group $RESOURCE_GROUP --yes

# Using YAML file: https://learn.microsoft.com/en-us/azure/container-apps/azure-resource-manager-api-spec?tabs=yaml#container-app-examples
LOG_ANALYTICS_WORKSPACE_CLIENT_ID=`az containerapp env show --name $CONTAINERAPPS_ENVIRONMENT --resource-group $RESOURCE_GROUP --query properties.appLogsConfiguration.logAnalyticsConfiguration.customerId --out tsv`

az monitor log-analytics query \
--workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
--analytics-query "ContainerAppConsoleLogs_CL | where ContainerAppName_s == 'tour-of-heroes-api' | project Log_s | take 5" \
--out table

az monitor log-analytics query \
--workspace $LOG_ANALYTICS_WORKSPACE_CLIENT_ID \
--analytics-query "ContainerAppSystemLogs_CL | where Type_s != 'Normal'| project Log_s | take 10" \
--out table


# Test API

CAPPS_HERO_API=$(az containerapp show --name tour-of-heroes-api --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)
CAPPS_VILLAINS_API=$(az containerapp show --name tour-of-villains-api --resource-group $RESOURCE_GROUP --query "properties.configuration.ingress.fqdn" -o tsv)

# Variables for cURL commands
HERO_API_URL=http://$CAPPS_HERO_API/api/hero
VILLAIN_API_URL=http://$CAPPS_VILLAINS_API/villain

# Check if hero api is working
curl -L $HERO_API_URL | jq

curl -L --post301 --header "Content-Type: application/json" \
  --request POST \
  --data '{
    "name": "Batman",
    "description": "Un multimillonario magnate empresarial y filántropo dueño de Empresas Wayne en Gotham City. Después de presenciar el asesinato de sus padres, el Dr. Thomas Wayne y Martha Wayne en un violento y fallido asalto cuando era niño, juró venganza contra los criminales, un juramento moderado por el sentido de la justicia.",
    "alterEgo": "Bruce Wayne" 
   
}' \
  $HERO_API_URL | jq

# Get heroes again
curl -L $HERO_API_URL | jq
curl -L $VILLAIN_API_URL | jq

# Check if villain api is working
curl -L --post301 --header "Content-Type: application/json" \
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
# kubectl logs -l app=tour-of-heroes-api -c tour-of-heroes-api
az containerapp logs show --resource-group $RESOURCE_GROUP -n tour-of-heroes-api --container tour-of-heroes-api --follow

# Check if service to service invocation is working
curl -L $HERO_API_URL/villain/spiderman | jq

az group delete -n $RESOURCE_GROUP -y --no-wait

# https://learn.microsoft.com/en-us/azure/container-apps/dapr-overview?tabs=bicep1%2Cyaml#unsupported-dapr-capabilities

# https://techcommunity.microsoft.com/t5/apps-on-azure-blog/accelerating-azure-container-apps-with-the-azure-cli-and-compose/ba-p/3516636