# Aplicación de ejemplo en Angular: Tour Of Heroes

Este proyecto es una implementación de una API en .NET para el fronted del [tutorial de AngularJS](https://angular.io/tutorial), que cuando finaliza lo hace generando la API en memoria. Esta se apoya en una base de datos SQL Server que puedes generar usando Docker:

```
docker run \
-e 'ACCEPT_EULA=Y' \
-e 'SA_PASSWORD=Password1!' \
-e 'MSSQL_PID=Express' \
--name sqlserver \
-p 1433:1433 -d mcr.microsoft.com/mssql/server:latest

#O si tienes un Apple M1
docker run \
--name azuresqledge \
--network sqlserver-vnet \
--cap-add SYS_PTRACE -e 'ACCEPT_EULA=1' \
-e 'MSSQL_SA_PASSWORD=Password1!' \
-p 1433:1433 \
-d mcr.microsoft.com/azure-sql-edge
```

Tienes los pasos en el archivo [create-local-database.sh](https://github.com/0GiS0/tour-of-heroes-dotnet-api/blob/main/create-local-database.sh)

Si no hay otro archivo, la configuración de la base de datos la coge del llamado [appsettings.json](https://github.com/0GiS0/tour-of-heroes-dotnet-api/blob/main/appsettings.json) pero debes de tener cuidado de subir información sensible a este, por lo que es buena práctica crearse en local uno llamado **appsettings.Development.json** que el proyecto de .NET sabrá reconocer, lo utilizará en su lugar y no se subirá a GitHub. Este debe tener la siguiente forma (al igual que el de appsettings.json):

```
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

## Cómo lo ejecuto

Si estás en Visual Studio Code, o Visual Studio 2019/2022, puedes ejecutar el proyecto simplemente pulsando F5.

Si estás usando cualquier otro método puedes lanzarlo ejecutando el siguiente comando:

```
dotnet run
```

El proceso arrancará y estará disponible en esta dirección: [https://localhost:5001/api/hero](https://localhost:5001/api/hero).

## Cómo añadir héroes

La primera vez que lo ejecutes no verás ni un solo heroe. Para ayudarte en esta tarea, puedes instalar en Visual Studio Code la extensión [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) y ejecutar las peticiones del archivo [client.http](https://github.com/0GiS0/tour-of-heroes-dotnet-api/blob/main/client.http)