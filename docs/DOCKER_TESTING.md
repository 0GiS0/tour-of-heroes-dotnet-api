# 🐳 Guía de Pruebas Docker

Esta guía explica cómo probar la imagen Docker con diferentes configuraciones de base de datos.

## 📋 Pre-requisitos

- Docker instalado
- Puertos 8080, 1433 (SQL Server), 5432 (PostgreSQL) disponibles

## 🏗️ Construcción de la Imagen

```bash
# Desde el directorio raíz del proyecto
docker build -t tour-of-heroes-api:test -f build/docker/Dockerfile src/
```

## ✅ Verificar Variables de Entorno

Puedes verificar las variables de entorno configuradas en la imagen:

```bash
docker run --rm tour-of-heroes-api:test env | grep -E "DATABASE_PROVIDER|ASPNETCORE"
```

**Salida esperada:**
```
ASPNETCORE_URLS=http://+:8080
ASPNETCORE_ENVIRONMENT=Production
DATABASE_PROVIDER=SqlServer
```

## 🧪 Prueba 1: SQL Server (Proveedor por Defecto)

### Paso 1: Iniciar SQL Server

**Linux/macOS (Intel):**
```bash
docker run -d \
  --name sqlserver \
  -e 'ACCEPT_EULA=Y' \
  -e 'SA_PASSWORD=YourStrong@Password1' \
  -e 'MSSQL_PID=Express' \
  -p 1433:1433 \
  mcr.microsoft.com/mssql/server:2022-latest
```

**macOS (Apple Silicon - ARM):**
```bash
docker run -d \
  --name sqlserver \
  --cap-add SYS_PTRACE \
  -e 'ACCEPT_EULA=1' \
  -e 'MSSQL_SA_PASSWORD=YourStrong@Password1' \
  -p 1433:1433 \
  mcr.microsoft.com/azure-sql-edge
```

### Paso 2: Iniciar la API

```bash
docker run -d \
  --name tour-api-sqlserver \
  -p 8080:8080 \
  -e "ConnectionStrings__DefaultConnection=Server=host.docker.internal,1433;Database=heroes;User Id=sa;Password=YourStrong@Password1;TrustServerCertificate=True" \
  tour-of-heroes-api:test
```

### Paso 3: Verificar

```bash
# Health check
curl http://localhost:8080/api/health

# Info de la API (debería mostrar DatabaseProvider: SqlServer)
curl http://localhost:8080

# Ver logs
docker logs tour-api-sqlserver
```

### Paso 4: Limpieza

```bash
docker stop tour-api-sqlserver sqlserver
docker rm tour-api-sqlserver sqlserver
```

## 🧪 Prueba 2: PostgreSQL

### Paso 1: Iniciar PostgreSQL

```bash
docker run -d \
  --name postgres \
  -e POSTGRES_DB=heroes \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=YourStrong@Password1 \
  -p 5432:5432 \
  postgres:16-alpine
```

### Paso 2: Iniciar la API con PostgreSQL

```bash
docker run -d \
  --name tour-api-postgres \
  -p 8081:8080 \
  -e "DATABASE_PROVIDER=PostgreSQL" \
  -e "ConnectionStrings__PostgreSQL=Host=host.docker.internal;Database=heroes;Username=postgres;Password=YourStrong@Password1" \
  tour-of-heroes-api:test
```

**Nota:** Usamos puerto 8081 para evitar conflictos si aún está corriendo la prueba anterior.

### Paso 3: Verificar

```bash
# Health check
curl http://localhost:8081/api/health

# Info de la API (debería mostrar DatabaseProvider: PostgreSQL)
curl http://localhost:8081

# Ver logs
docker logs tour-api-postgres
```

### Paso 4: Limpieza

```bash
docker stop tour-api-postgres postgres
docker rm tour-api-postgres postgres
```

## 🐳 Prueba 3: Docker Compose

### Paso 1: Crear docker-compose.test.yml

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
      - ConnectionStrings__PostgreSQL=Host=postgres;Database=heroes;Username=postgres;Password=Test@Password123
    depends_on:
      postgres:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: heroes
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: Test@Password123
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

volumes:
  postgres_data:
```

### Paso 2: Ejecutar

```bash
docker compose -f docker-compose.test.yml up -d
```

### Paso 3: Verificar

```bash
# Ver logs
docker compose -f docker-compose.test.yml logs -f

# Probar health check
curl http://localhost:8080/api/health

# Ver información de la API
curl http://localhost:8080
```

### Paso 4: Limpieza

```bash
docker compose -f docker-compose.test.yml down -v
```

## ✅ Checklist de Validación

- [ ] La imagen se construye sin errores
- [ ] Las variables de entorno están configuradas correctamente
- [ ] La API inicia con SQL Server (proveedor por defecto)
- [ ] La API inicia con PostgreSQL al especificar `DATABASE_PROVIDER=PostgreSQL`
- [ ] El health check responde correctamente (http://localhost:8080/api/health)
- [ ] El endpoint raíz muestra el proveedor correcto
- [ ] Los logs no muestran errores críticos
- [ ] El puerto 8080 está correctamente expuesto

## 🔍 Troubleshooting

### Error: "Connection refused"

- Verificar que `host.docker.internal` está disponible (en Linux puede necesitar `--add-host=host.docker.internal:host-gateway`)
- En Linux, usar la IP del host en lugar de `host.docker.internal`

### Error: "Unable to connect to database"

- Verificar que el contenedor de base de datos está corriendo
- Verificar el connection string
- Verificar que los puertos están correctamente mapeados

### Error: "Address already in use"

- Cambiar el puerto externo: `-p 8081:8080` en lugar de `-p 8080:8080`

---

*This documentation was generated by GitHub Copilot 🤖*
