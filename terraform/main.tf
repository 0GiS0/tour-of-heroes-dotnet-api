# Azure provider
provider "azurerm" {
  features {}
}

# Variables
variable "db_user" {

}

variable "db_password" {

}


# Resource group
resource "azurerm_resource_group" "rg" {
  name     = "Tour-Of-Heroes"
  location = "North Europe"
}

# Azure App Service Plan
resource "azurerm_app_service_plan" "plan" {
  name                = "tour-of-heroes-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}


# Create a Azure SQL Server 
resource "azurerm_sql_server" "sqlserver" {
  name                         = "heroserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_user
  administrator_login_password = var.db_password

}

# Allow Azure services and resources to access this server
resource "azurerm_sql_firewall_rule" "sqlserver" {
  name                = "allow-azure-services"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sqlserver.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# Create a database
resource "azurerm_sql_database" "sqldatabase" {
  name                = "heroes"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_sql_server.sqlserver.name
  location            = azurerm_resource_group.rg.location
  edition             = "Basic"
}

# Create Web App
resource "azurerm_app_service" "web" {
  name                = "tour-of-heroes-webapi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  app_service_plan_id = azurerm_app_service_plan.plan.id

  # Connection Strings
  connection_string {
    name  = "DefaultConnection"
    value = "Server=tcp:${azurerm_sql_server.sqlserver.name}.database.windows.net,1433;Initial Catalog=${azurerm_sql_database.sqldatabase.name};Persist Security Info=False;User ID=${var.db_user};Password=${var.db_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    type  = "SQLAzure"
  }
}
