terraform {
  backend "azurerm" {
    resource_group_name  = "erjositotfstate"
    storage_account_name = "erjositotfstate"
    container_name       = "azpolicy"
    key                  = "azpolicy.tfstate"
  }
}
 
provider "azurerm" {
  features {}
}
