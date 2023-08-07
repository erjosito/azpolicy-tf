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
    container_name       = "dnszonegrouppolicy"
    key                  = "dnszonegrouppolicy.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# Custom Azure Policy
resource "azurerm_policy_definition" "zone_group" {
  for_each              = toset(var.endpoint_types)
  name                  = "${each.value}-zone-group"
  policy_type           = "Custom"
  mode                  = "All"
  display_name          = "Connect ${each.value} endpoints to DNS private zones"
  management_group_id   = var.definition_management_group
  policy_rule           = replace(file("${path.module}/policy-rule.json"), "_ENDPOINT_TYPE_", each.value)
  parameters            = replace(file("${path.module}/policy-parameters.json"), "_ENDPOINT_TYPE_", each.value)
}

# Policy set (aka initiative)
resource "azurerm_policy_set_definition" "zone_group" {
  name                  = "zone-group"
  policy_type           = "Custom"
  display_name          = "Zone Group for endpoints"
  management_group_id   = var.definition_management_group
  parameters            = file("${path.module}/initiative-parameters.json")
  dynamic policy_definition_reference {
    for_each = toset(var.endpoint_types)
    content {
      policy_definition_id = azurerm_policy_definition.zone_group[each.value].id
      parameter_values = "\"${each.value}PrivateDnsZoneId\": {\"value\": \"[parameters('${each.value}PrivateDnsZoneId')]\"}"
    }
  }
}

# Assignment
# resource "azurerm_management_group_policy_assignment" "zone_group" {
#   name                 = "Resources in WestEurope"      # Max 24 characters
#   management_group_id  = var.definition_management_group
#   policy_definition_id = azurerm_policy_set_definition.zone_group.id
#   description          = "Audit resources in West Europe"
#   display_name         = "Audit resources in West Europe"
#   parameters           = file("${path.module}/assignment-parameters.json")
# }
