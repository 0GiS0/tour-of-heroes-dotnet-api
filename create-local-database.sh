# Create local database on Docker Mac/Linux
docker run \
-e 'ACCEPT_EULA=Y' \
-e 'SA_PASSWORD=Password1!' \
-e 'MSSQL_PID=Express' \
--name sqlserver \
 -v mssqlserver_volume:/var/opt/mssql \
-p 1433:1433 -d mcr.microsoft.com/mssql/server:latest

# Apple M1

#Create a network
docker network create sqlserver-vnet

#Create a container with Azure SQL Edge
docker run \
--name azuresqledge \
--network sqlserver-vnet \
--cap-add SYS_PTRACE -e 'ACCEPT_EULA=1' \
-e 'MSSQL_SA_PASSWORD=Password1!' \
 -v mssqlserver_volume:/var/opt/mssql \
-p 1433:1433 \
-d mcr.microsoft.com/azure-sql-edge

# Create local database on Windows (PowerShell)
docker run `
-e 'ACCEPT_EULA=Y' `
-e 'SA_PASSWORD=Password1!' `
-e 'MSSQL_PID=Express' `
--name sqlserver `
 -v mssqlserver_volume:/var/opt/mssql `
-p 1433:1433 -d mcr.microsoft.com/mssql/server:latest

#and just execute the Web API using this database
#Connection string: Server=localhost,1433;Initial Catalog=heroes;Persist Security Info=False;User ID=sa;Password=Password1!;

# Terraform
terraform init \
-backend-config="storage_account_name=tfstateslemon" \
-backend-config="container_name=demo" \
-backend-config="access_key=82U256laUIzzWyCJ2DfC9rhgAoO4JlIvE7xNB0VcfwaDMI6LbFca94QYRA3no3yzRiCuGE9itlwHhdSlVf81wA=="

terraform plan -out=tfplan

terraform apply tfplan \
-backend-config="storage_account_name=${secrets.AZURE_STORAGE_ACCOUNT_NAME}" \
-backend-config="container_name=${secrets.AZURE_STORAGE_CONTAINER_NAME}" \
-backend-config="access_key=${secrets.AZURE_STORAGE_ACCESS_KEY}"

az login

AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create a service principal
az ad sp create-for-rbac --name "terraform-sp" --role contributor --scopes "/subscriptions/$AZURE_SUBSCRIPTION_ID"
