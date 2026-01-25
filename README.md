# 🦸 Tour of Heroes API

![.NET](https://img.shields.io/badge/.NET-9.0-512BD4?style=flat&logo=dotnet)
![License](https://img.shields.io/badge/license-MIT-green?style=flat)
![SQL Server](https://img.shields.io/badge/SQL%20Server-supported-CC2927?style=flat&logo=microsoftsqlserver)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-supported-4169E1?style=flat&logo=postgresql)
![Docker](https://img.shields.io/badge/Docker-ready-2496ED?style=flat&logo=docker)
![Terraform](https://img.shields.io/badge/Terraform-IaC-7B42BC?style=flat&logo=terraform)

![Tour of Heroes](docs/images/heroes%20by%20microsoft%20designer.jpeg)

API REST en **.NET 9** para el tutorial [Tour of Heroes](https://angular.io/tutorial) de Angular, con soporte para **SQL Server** y **PostgreSQL**, observabilidad completa con **OpenTelemetry**, y despliegue en **Azure** con Terraform.

---

## ✨ Características

| Característica | Descripción |
|----------------|-------------|
| 🦸 **CRUD de Héroes** | API REST completa para gestionar héroes |
| 🗄️ **Multi-Base de Datos** | Soporte para SQL Server y PostgreSQL |
| 🛡️ **Rate Limiting** | Protección contra abuso de la API |
| 📊 **OpenTelemetry** | Trazas, métricas y logs distribuidos |
| 📈 **Prometheus** | Métricas exportadas en `/metrics` |
| 🔍 **Jaeger** | Trazas distribuidas |
| 📉 **Grafana** | Dashboards de monitorización |
| 🐳 **Docker** | Contenedores listos para producción |
| ☁️ **Terraform** | Infraestructura como código para Azure |
| 🧪 **Tests** | Tests unitarios con xUnit y Moq |

---

## 🚀 Inicio Rápido

### Requisitos

- [.NET 9.0 SDK](https://dotnet.microsoft.com/download/dotnet/9.0)
- [Docker](https://www.docker.com/get-started) (opcional, para base de datos)

### Opción 1: Dev Container (Recomendado) 🐳

Este proyecto incluye un **Dev Container** con todo lo necesario:

```bash
# Abrir en VS Code con la extensión Dev Containers
code .
# Ctrl+Shift+P -> "Dev Containers: Reopen in Container"
```

### Opción 2: Ejecución Local

```bash
# Clonar el repositorio
git clone https://github.com/0GiS0/tour-of-heroes-dotnet-api.git
cd tour-of-heroes-dotnet-api

# Restaurar dependencias
dotnet restore

# Ejecutar la API
cd src
dotnet run
```

La API estará disponible en:
- 🏠 **API Info**: [http://localhost:5020](http://localhost:5020)
- 📖 **Swagger**: [http://localhost:5020/swagger](http://localhost:5020/swagger)
- 📈 **Métricas**: [http://localhost:5020/metrics](http://localhost:5020/metrics)

---

## 🗄️ Configuración de Base de Datos

La API soporta **SQL Server** y **PostgreSQL**. Configura el proveedor con la variable de entorno `DATABASE_PROVIDER`.

### SQL Server (Por defecto)

```bash
# Iniciar SQL Server con Docker
docker run \
  -e 'ACCEPT_EULA=Y' \
  -e 'SA_PASSWORD=YourStrong@Password1' \
  -e 'MSSQL_PID=Express' \
  --name sqlserver \
  -p 1433:1433 \
  -d mcr.microsoft.com/mssql/server:2022-latest
```

**Para Mac con chip ARM:**
```bash
docker run \
  --name azuresqledge \
  --cap-add SYS_PTRACE \
  -e 'ACCEPT_EULA=1' \
  -e 'MSSQL_SA_PASSWORD=YourStrong@Password1' \
  -p 1433:1433 \
  -d mcr.microsoft.com/azure-sql-edge
```

### PostgreSQL

```bash
# Iniciar PostgreSQL con Docker
docker run \
  --name postgres \
  -e POSTGRES_DB=heroes \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=YourStrong@Password1 \
  -p 5432:5432 \
  -d postgres:16-alpine
```

### Variables de Entorno

| Variable | Descripción | Valores | Default |
|----------|-------------|---------|---------|
| `DATABASE_PROVIDER` | Proveedor de BD | `SqlServer`, `PostgreSQL` | `SqlServer` |
| `ConnectionStrings__DefaultConnection` | Connection string SQL Server | string | - |
| `ConnectionStrings__PostgreSQL` | Connection string PostgreSQL | string | - |

**Ejemplo de uso:**
```bash
# Usar PostgreSQL
export DATABASE_PROVIDER=PostgreSQL
export ConnectionStrings__PostgreSQL="Host=localhost;Database=heroes;Username=postgres;Password=YourStrong@Password1"
dotnet run
```

---

## 📡 API Endpoints

| Método | Ruta | Descripción | Rate Limit |
|--------|------|-------------|------------|
| `GET` | `/` | Información de la API | ✅ |
| `GET` | `/api/health` | Health check | ❌ |
| `GET` | `/api/heroes` | Listar todos los héroes | ✅ |
| `GET` | `/api/heroes/{id}` | Obtener héroe por ID | ✅ |
| `POST` | `/api/heroes` | Crear nuevo héroe | ✅ |
| `PUT` | `/api/heroes/{id}` | Actualizar héroe | ✅ |
| `DELETE` | `/api/heroes/{id}` | Eliminar héroe | ✅ |
| `GET` | `/metrics` | Métricas Prometheus | ❌ |
| `GET` | `/swagger` | Documentación Swagger | ❌ |

### Ejemplos con cURL

```bash
# Listar héroes
curl http://localhost:5020/api/heroes

# Crear héroe
curl -X POST http://localhost:5020/api/heroes \
  -H "Content-Type: application/json" \
  -d '{"name": "Superman", "alterEgo": "Clark Kent"}'

# Obtener héroe
curl http://localhost:5020/api/heroes/1
```

También puedes usar el archivo [client.http](src/client.http) con la extensión [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) de VS Code.

---

## 📊 Observabilidad

El proyecto incluye observabilidad completa con **OpenTelemetry**:

| Componente | Puerto | URL |
|------------|--------|-----|
| 📈 Prometheus | 9090 | [http://localhost:9090](http://localhost:9090) |
| 🔍 Jaeger | 16686 | [http://localhost:16686](http://localhost:16686) |
| 📉 Grafana | 3000 | [http://localhost:3000](http://localhost:3000) |

### Métricas disponibles

- `http_server_request_duration_seconds` - Duración de peticiones HTTP
- `http_server_active_requests` - Peticiones activas
- `db_client_operation_duration` - Duración de operaciones de BD
- `process_cpu_usage` - Uso de CPU
- `process_memory_usage` - Uso de memoria

---

## 🐳 Docker

### Build de la imagen

```bash
# Desde el directorio raíz del proyecto
docker build -t tour-of-heroes-api -f build/docker/Dockerfile src/
```

### Variables de entorno del contenedor

El Dockerfile incluye las siguientes variables de entorno configuradas por defecto:

| Variable | Valor por defecto | Descripción |
|----------|-------------------|-------------|
| `DATABASE_PROVIDER` | `SqlServer` | Proveedor de base de datos (`SqlServer` o `PostgreSQL`) |
| `ASPNETCORE_URLS` | `http://+:8080` | URLs en las que escucha la aplicación |
| `ASPNETCORE_ENVIRONMENT` | `Production` | Entorno de ejecución |
| `OTEL_SERVICE_NAME` | `tour-of-heroes-api` | Nombre del servicio para OpenTelemetry |

### Ejecutar con SQL Server (por defecto)

```bash
# SQL Server es el proveedor por defecto, no es necesario especificar DATABASE_PROVIDER
docker run -d \
  -p 8080:8080 \
  -e "ConnectionStrings__DefaultConnection=Server=host.docker.internal,1433;Database=heroes;User Id=sa;Password=YourPassword;TrustServerCertificate=True" \
  tour-of-heroes-api
```

### Ejecutar con PostgreSQL

```bash
# Especificar DATABASE_PROVIDER=PostgreSQL para usar PostgreSQL
docker run -d \
  -p 8080:8080 \
  -e "DATABASE_PROVIDER=PostgreSQL" \
  -e "ConnectionStrings__PostgreSQL=Host=host.docker.internal;Database=heroes;Username=postgres;Password=YourPassword" \
  tour-of-heroes-api
```

### Docker Compose ejemplo

```yaml
version: "3.8"
services:
  api:
    build:
      context: src
      dockerfile: ../build/docker/Dockerfile
    ports:
      - "8080:8080"
    environment:
      - DATABASE_PROVIDER=PostgreSQL
      - ConnectionStrings__PostgreSQL=Host=postgres;Database=heroes;Username=postgres;Password=secret
    depends_on:
      - postgres

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: heroes
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: secret
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

> 📖 **Guía completa de pruebas Docker:** Ver [docs/DOCKER_TESTING.md](docs/DOCKER_TESTING.md) para instrucciones detalladas sobre cómo probar la imagen con diferentes proveedores de base de datos.

---

## 🏗️ Estructura del Proyecto

```
tour-of-heroes-dotnet-api/
├── 📁 src/                      # Código fuente de la API
│   ├── 📁 Controllers/          # Controladores REST
│   ├── 📁 Models/               # Modelos y DbContext
│   ├── 📁 Repositories/         # Patrón Repository
│   ├── 📁 Interfaces/           # Interfaces
│   ├── 📄 Program.cs            # Punto de entrada
│   └── 📄 appsettings.json      # Configuración
├── 📁 tests/                    # Tests unitarios
├── 📁 build/
│   ├── 📁 docker/               # Dockerfile
│   └── 📁 scripts/              # Scripts de utilidad
├── 📁 infrastructure/           # Terraform para Azure
├── 📁 docs/                     # Documentación adicional
└── 📄 README.md
```

---

## ☁️ Despliegue en Azure

El proyecto incluye infraestructura como código con **Terraform**:

```bash
cd infrastructure

# Inicializar Terraform
terraform init

# Ver plan de despliegue
terraform plan -var="database_provider=SqlServer"

# Aplicar cambios
terraform apply -var="database_provider=SqlServer"
```

**Recursos creados:**
- Azure App Service (Windows, .NET 9)
- Azure SQL Database **o** PostgreSQL Flexible Server (configurable)
- App Service Plan (S1)
- Resource Group

**Variables disponibles:**
- `database_provider`: `SqlServer` (default) o `PostgreSQL`
- Ver [infrastructure/README.md](infrastructure/README.md) para más detalles

---

## 🧪 Tests

```bash
# Ejecutar todos los tests
cd tests
dotnet test

# Con cobertura
dotnet test --collect:"XPlat Code Coverage"
```

---

## 🤝 Contribuir

1. Fork del repositorio
2. Crear rama feature (`git checkout -b feature/AmazingFeature`)
3. Commit de cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

---

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver [LICENSE](LICENSE) para más detalles.

---

<p align="center">
  <i>This code was generated by GitHub Copilot 🤖</i>
</p>