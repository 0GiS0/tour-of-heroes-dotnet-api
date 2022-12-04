dapr run --app-id tour-of-heroes-api --app-port 5222 -- dotnet run

# Create Jaeger container
docker run -d --name jaeger \
  -e COLLECTOR_ZIPKIN_HOST_PORT=:9412 \
  -p 16686:16686 \
  -p 9412:9412 \
  jaegertracing/all-in-one

# To view traces
http://localhost:16686

#Pub sub
dapr publish --publish-app-id tour-of-villains-api --pubsub villain-pub-sub --topic villains --data '{"orderId": "100"}'

# Create an Azure Key Vault and authorize a Service Principal

### Variables ###
LOCATION="northeurope"
RESOURCE_GROUP="dapr-experiments"
KEYVAULT_NAME="azkeyvaultdaprexp"
AZ_AD_APP_NAME="tour-of-heroes-dapr"

# Create Azure AD app
APP_ID=$(az ad app create --display-name "${AZ_AD_APP_NAME}"  | jq -r .appId)

# Create a client secret valid for 2 years
az ad app credential reset --id "${APP_ID}" --years 2

# Create a service principal
SERVICE_PRINCIPAL_ID=$(az ad sp create --id "${APP_ID}"  | jq -r .id)

# Create a resource group
RESOURE_GROUP_ID=$(az group create --name "${RESOURCE_GROUP}" --location $LOCATION  | jq -r .id)

# Create an Azure Key Vault
az keyvault create \
  --name "${KEYVAULT_NAME}" \
  --enable-rbac-authorization true \
  --resource-group "${RESOURCE_GROUP}" \
  --location "${LOCATION}"

# Assign a role to the service principal
az role assignment create \
  --assignee "${SERVICE_PRINCIPAL_ID}" \
  --role "Key Vault Secrets User" \
  --scope "${RESOURE_GROUP_ID}/providers/Microsoft.KeyVault/vaults/${KEYVAULT_NAME}"

# Assing role to  Microsoft Azure CLI
# https://learn.microsoft.com/en-us/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in#:~:text=Microsoft%20Azure%20CLI,461a%2Dbbee%2D02f9e1bf7b46
az role assignment create \
  --assignee 04b07795-8ddb-461a-bbee-02f9e1bf7b46 \
  --role "Key Vault Secrets Officer" \
  --scope "${RESOURE_GROUP_ID}/providers/Microsoft.KeyVault/vaults/${KEYVAULT_NAME}"

# Add new secret to the az key vault
az keyvault secret set -n ConnectionString \
--value 'Server=localhost,1433;Initial Catalog=heroes;Persist Security Info=False;User ID=sa;Password=Password1!' \
--vault-name $KEYVAULT_NAME

# Test the secret store with Azure Key Vault!