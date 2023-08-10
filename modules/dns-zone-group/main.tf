terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.7.0"
    }
  }
}

data "azurerm_subscription" "primary" {
}

locals {
  initiative_param_template = <<PARAM_TEMPLATE
  {
    "type": "String",
    "metadata": {
        "displayName": "Private DNS Zone ID",
        "description": "Private DNS Zone ID",
        "strongType": "Microsoft.Network/privateDnsZones"
    }
  }
PARAM_TEMPLATE
}

# Private DNS zones
resource "azurerm_private_dns_zone" "example" {
  for_each = toset(values(var.zone_assignments))
  name     = each.value
  resource_group_name = var.zone_rg_name
}

# Custom Azure Policy
resource "azurerm_policy_definition" "zone_group" {
  for_each              = toset(keys(var.zone_assignments))
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
  parameters            = jsonencode({for s in keys(var.zone_assignments) : "${s}PrivateDnsZoneId" => jsondecode(local.initiative_param_template)})
  dynamic policy_definition_reference {
    for_each = toset(keys(var.zone_assignments))
    content {
      policy_definition_id = azurerm_policy_definition.zone_group[policy_definition_reference.value].id
      parameter_values = "{\"${policy_definition_reference.value}PrivateDnsZoneId\": {\"value\": \"[parameters('${policy_definition_reference.value}PrivateDnsZoneId')]\"}}"
    }
  }
}

# Assignment
resource "azurerm_management_group_policy_assignment" "zone_group" {
  name                 = "PLink and DNS"      # Max 24 characters
  location             = var.assignment_location
  management_group_id  = var.definition_management_group
  policy_definition_id = azurerm_policy_set_definition.zone_group.id
  description          = "Link automatically private endpoints to DNS private zones"
  display_name         = "Link automatically private endpoints to DNS private zones"
  parameters           = jsonencode({for k, v in var.zone_assignments : "${k}PrivateDnsZoneId" => jsondecode("{ \"value\": \"${data.azurerm_subscription.primary.id}/resourceGroups/${var.zone_rg_name}/providers/Microsoft.Network/privateDnsZones/${v}\" }")})
  identity {
    type = "SystemAssigned"
  }
}

# Role assignment for the DINE policy
resource "azurerm_role_assignment" "dine-policy" {
  for_each = var.assignment_msi_roles
  principal_id                     = azurerm_management_group_policy_assignment.zone_group.identity[0].principal_id
  scope                            = var.definition_management_group
  role_definition_name             = each.value
  skip_service_principal_aad_check = true
}