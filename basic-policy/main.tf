terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
  }

  # Update this block with the location of your terraform state file
  backend "azurerm" {
    resource_group_name  = "erjositotfstate"
    storage_account_name = "erjositotfstate"
    container_name       = "basicpolicy"
    key                  = "basicpolicy.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Custom Azure Policy
resource "azurerm_policy_definition" "resource_location" {
  name                  = "resource-location"
  policy_type           = "Custom"
  mode                  = "All"
  display_name          = "Disallowed resource Location"
  management_group_id   = var.definition_management_group
  policy_rule           = file("${path.module}/policy-rule.json")
  parameters            = file("${path.module}/policy-parameters.json")
}

# Policy set (aka initiative)
resource "azurerm_policy_set_definition" "resource_location" {
  name                  = "resource-location"
  policy_type           = "Custom"
  display_name          = "Resource Location"
  management_group_id   = var.definition_management_group
  parameters            = file("${path.module}/initiative-parameters.json")
  policy_definition_reference {
    policy_definition_id = azurerm_policy_definition.resource_location.id
    parameter_values = jsonencode({
      disallowedLocations = {
        value = "[parameters('disallowedLocations')]"
      }
    })
  }
}

# Assignment
resource "azurerm_policy_assignment" "resource_location" {
  name                 = "Audit resources in West Europe"
  scope                = var.definition_management_group
  policy_definition_id = azurerm_policy_set_definition.resource_location.id
  description          = "Audit resources in West Europe"
  display_name         = "Audit resources in West Europe"
  parameters           = file("${path.module}/assignment-parameters.json")
}