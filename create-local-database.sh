# Create local database on Docker
docker run \
-e 'ACCEPT_EULA=Y' \
-e 'SA_PASSWORD=Password1!' \
-e 'MSSQL_PID=Express' \
--name sqlserver \
-p 1433:1433 -d mcr.microsoft.com/mssql/server:latest

# Create database 
docker exec -it sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'Password1!' -Q 'CREATE DATABASE [heroes]'

# Apple M1

#Create a network
docker network create sqlserver-vnet

#Create a container with Azure SQL Edge
docker run \
--name azuresqledge \
--network sqlserver-vnet \
--cap-add SYS_PTRACE -e 'ACCEPT_EULA=1' \
-e 'MSSQL_SA_PASSWORD=Password1!' \
-p 1433:1433 \
-d mcr.microsoft.com/azure-sql-edge

#Create a database (this step is not necessary)
docker run -it --network sqlserver-vnet mcr.microsoft.com/mssql-tools
sqlcmd -S azuresqledge -U SA -P 'Password1!' -Q 'CREATE DATABASE [heroes]'

#and just execute the Web API using this database
#Connection string: Server=localhost,1433;Initial Catalog=heroes;Persist Security Info=False;User ID=sa;Password=Password1!;
