terraform {
  backend "azurerm" {
    resource_group_name  = "erjositotfstate"
    storage_account_name = "erjositotfstate"
    container_name       = "azpolicy"
    key                  = "azpolicy.tfstate"
  }
}
 
provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you're using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}
 
data "azurerm_client_config" "current" {}

module "dine_dns_zone_group" {
  source              = "..//modules/definition"
  policy_name         = "dnszonegroup_dine"
  display_name        = "Create DNS Zone Group for private endpoints"
  policy_category     = "Private Link"
  management_group_id = data.azurerm_management_group.org.id
}