FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080

# Environment variables
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production
ENV OTEL_SERVICE_NAME=tour-of-heroes-api

# Database provider configuration
# Supported values: SqlServer, PostgreSQL
ENV DATABASE_PROVIDER=SqlServer

# Creates a non-root user with an explicit UID and adds permission to access the /app folder
# For more info, please refer to https://aka.ms/vscode-docker-dotnet-configure-containers
RUN adduser -u 5678 --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

FROM mcr.microsoft.com/dotnet/sdk:9.0.101 AS build

ARG TARGETARCH
ARG TARGETOS

RUN arch=$TARGETARCH \
    && if [ "$arch" = "amd64" ]; then arch="x64"; fi \
    && echo $TARGETOS-$arch > /tmp/rid


WORKDIR /src
COPY ["tour-of-heroes-api.csproj", "./"]
# RUN dotnet restore "tour-of-heroes-api.csproj"

RUN dotnet restore -r $(cat /tmp/rid) "tour-of-heroes-api.csproj" 

COPY . .
# WORKDIR "/src/."
# RUN dotnet build "tour-of-heroes-api.csproj" -c Release -o /app/build

FROM build AS publish
# RUN dotnet publish "tour-of-heroes-api.csproj" -c Release -o /app/publish /p:UseAppHost=false
RUN dotnet publish "tour-of-heroes-api.csproj" -c Release -o /app/publish -r $(cat /tmp/rid) --self-contained false --no-restore

FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Install curl
USER root
RUN apt-get update && apt-get install -y curl
USER appuser

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/api/health || exit 1

ENTRYPOINT ["dotnet", "tour-of-heroes-api.dll"]
