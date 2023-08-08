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

# Private DNS zones
resource "azurerm_private_dns_zone" "example" {
  for_each = toset(values(var.zone_assignments))
  name     = each.value
  resource_group_name = var.zone_rg_name
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
  parameters            = jsonencode({for s in var.endpoint_types : "${s}PrivateDnsZoneId" => jsondecode(var.initiative_param_template)})
  dynamic policy_definition_reference {
    for_each = toset(var.endpoint_types)
    content {
      policy_definition_id = azurerm_policy_definition.zone_group[policy_definition_reference.value].id
      parameter_values = "{\"${policy_definition_reference.value}PrivateDnsZoneId\": {\"value\": \"[parameters('${policy_definition_reference.value}PrivateDnsZoneId')]\"}}"
    }
  }
}

# Assignment
resource "azurerm_management_group_policy_assignment" "zone_group" {
  name                 = "PLink and DNS"      # Max 24 characters
  management_group_id  = var.definition_management_group
  policy_definition_id = azurerm_policy_set_definition.zone_group.id
  description          = "Link automatically private endpoints to DNS private zones"
  display_name         = "Link automatically private endpoints to DNS private zones"
  parameters           = jsonencode({for k, v in var.zone_assignments : "${k}PrivateDnsZoneId" => jsondecode("{ \"value\": \"/subscriptions/${var.zone_subscription_id}/resourceGroups/${var.zone_rg_name}/providers/Microsoft.Network/privateDnsZones/${v}\" }")})
}
