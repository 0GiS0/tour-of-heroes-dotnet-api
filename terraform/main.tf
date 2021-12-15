provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
    name = "Tour-Of-Heroes"
    location = "North Europe"
}
