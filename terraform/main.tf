provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "Tour-Of-Heroes"
  location = "North Europe"
}

resource "azurerm_app_service_plan" "plan" {
  name                = "tour-of-heroes-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "web" {
  name = "tour-of-heroes-web-api"
  location = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  app_service_plan_id = azurerm_app_service_plan.plan.id

  

}
