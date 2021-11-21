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
