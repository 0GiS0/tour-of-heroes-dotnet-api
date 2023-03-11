# Terraform state in Azure Storage
terraform {
  backend "azurerm" {
    key = "tour-of-heroes-tf-state"
  }
}

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


# Create a Azure SQL Server 
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "heroserver"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.db_user
  administrator_login_password = var.db_password

}

# Allow Azure services and resources to access this server
resource "azurerm_mssql_firewall_rule" "sqlserver" {
  name             = "allow-azure-services"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Create a database
resource "azurerm_mssql_database" "sqldatabase" {
  name      = "heroes"
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "Basic"
}

# Azure App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "tour-of-heroes-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # sku {
  #   tier = "Standard"
  #   size = "S1"
  # }

  os_type = "Windows"

  sku_name = "S1"
}

# Create Web App
resource "azurerm_windows_web_app" "web" {
  name                = "tour-of-heroes-webapi"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  service_plan_id = azurerm_service_plan.plan.id

  site_config {
    application_stack {
      current_stack  = "dotnetcore"
      dotnet_version = "v7.0"
    }
  }

  # Connection Strings
  connection_string {
    name  = "DefaultConnection"
    value = "Server=tcp:${azurerm_mssql_server.sqlserver.name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sqldatabase.name};Persist Security Info=False;User ID=${var.db_user};Password=${var.db_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    type  = "SQLAzure"
  }
}

# Create Web App slot
resource "azurerm_windows_web_app_slot" "web" {
  name = "staging"

  app_service_id = azurerm_windows_web_app.web.id

  # Connection Strings
  connection_string {
    name  = "DefaultConnection"
    value = "Server=tcp:${azurerm_mssql_server.sqlserver.name}.database.windows.net,1433;Initial Catalog=${azurerm_mssql_database.sqldatabase.name};Persist Security Info=False;User ID=${var.db_user};Password=${var.db_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    type  = "SQLAzure"
  }

  site_config {
    
  }
}
