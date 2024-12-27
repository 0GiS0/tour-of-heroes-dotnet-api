# Tour of heroes API in .NET

![Tour of Heroes](docs/images/heroes%20by%20microsoft%20designer.jpeg)

This repository is an API in .NET for the AngularJS [Tour of Heroes tutorial](https://angular.io/tutorial), which when finished generates the API in memory. This one is supported by a SQL Server database that you can generate using Docker:

```bash
docker run \
-e 'ACCEPT_EULA=Y' \
-e 'SA_PASSWORD=Password1!' \
-e 'MSSQL_PID=Express' \
--name sqlserver \
-p 1433:1433 -d mcr.microsoft.com/mssql/server:latest
```

Or if you have a Mac with an ARM chip, you can use the following command:

```bash
docker run \
--name azuresqledge \
--network sqlserver-vnet \
--cap-add SYS_PTRACE -e 'ACCEPT_EULA=1' \
-e 'MSSQL_SA_PASSWORD=Password1!' \
-p 1433:1433 \
-d mcr.microsoft.com/azure-sql-edge
```

You have the steps in the file [create-local-database.sh](create-local-database.sh)

## Configuration

If there is no other file, the database configuration is taken from the so-called [appsettings.json](appsettings.json) but you must be careful not to upload sensitive information to this, so it is good practice to create a local one called **appsettings.Development.json** that the .NET project will recognize, use it instead and will not be uploaded to GitHub. 

```json
{
    "ConnectionStrings": {
        "DefaultConnection": "Server=localhost,1433;Initial Catalog=heroes;Persist Security Info=False;User ID=sa;Password=Password1!;"
    },
    "Logging": {
        "LogLevel": {
            "Default": "Information",
            "Microsoft": "Warning",
            "Microsoft.Hosting.Lifetime": "Information"
        }
    },
    "AllowedHosts": "*"
}
```

## How to run the project

If you are using Visual Studio Code, you can run the project by pressing `F5`. If you are using any other method you can launch it by running the following command:

```bash
dotnet run
```

The project will be available at [http://localhost:5000](http://localhost:5000) and the Swagger documentation at [http://localhost:5000/swagger](http://localhost:5000/swagger)

## How to add heroes

The first time you run the project, the database will be created but no heroes will be added. You can add them using the file called [client.http](client.http) that is in the root of the project. You can use the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension for Visual Studio Code to run the requests.