# DRY policy to associate private endpoints to DNS zones

The purpose of this module is reducing the size of the Terraform code required for automatic linking of private endpoints and private DNS zones in Azure.

Azure Private Endpoints need to be associated to Azure Private DNS Zones so that clients can resolve the service's name to a private instead of to a public address. This association can be done manually, or automatically as described in [Private Link and DNS integration at scale](https://learn.microsoft.com/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale).

The automatic integration is based on Azure Policies, which can detect when a Private Endpoints are not connected to any private zone, and establish that link. The issue with the policy described in the link above is that there are quite a few private endpoint types and corresponding DNS zones, as described in [Azure Private Endpoint DNS configuration](https://learn.microsoft.com/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration), so you would end up with over 1,000 lines of policy code only for this.

And yet, 95% of the code in those policies would be identical. This repo uses Terraform loop mechanisms to keep your Azure Policy code DRY (Don't Repeat Yourself) and compact. It uses templates to generate copies of the same basic policy customized for each private endpoint type.

The code consists of a Terraform module that, among other parameters, takes as input a dictionary with endpoint types as keys, and the private DNS zones that they will be associated to as values (see the [module README](./modules/dns-zone-group/README.md) for more details on the utilization). This parameter would look like this:

```terraform
    "blob"      = "privatelink.blob.core.windows.net"
    "file"      = "privatelink.file.core.windows.net"
    "table"     = "privatelink.table.core.windows.net"
    "queue"     = "privatelink.queue.core.windows.net"
    "dfs"       = "privatelink.dfs.core.windows.net"
    "web"       = "privatelink.web.core.windows.net"
    "sqlServer" = "privatelink.database.windows.net"
    "sites"     = "privatelink.azurewebsites.net"
```

The module will loop over every of the dictionary records and create the private DNS zone and the corresponding Azure Policy definition.

Note that this approach might not be valid for certain specific types of private endpoints:

- In some situations, the Azure service needs to control the private DNS zone and doesn't support Bring-Your-Own-Zone, for example Azure Kubernetes Service.
- In other cases, the DNS zone contains the resource region name, so the policy must be region-specific and match the resource region too (or extract the region of the resource and create a region-specific DNS zone), such as Azure Batch or Azure Container Registry.

And yet, this approach will cover for the vast majority of Azure Private Endpoint types, thus significantly reducing your Terraform code.

## Terraform loops

The module uses different Terraform techniques, most notably three types of loops:

- Resource loops with the `for_each` attribute
- Dynamic blocks with the `for_each` attribute
- Variable construction with the `for` operator

The module firstly creates the DNS zones over a resource loop powered by the `for_each` attribute of the resource:

```terraform
resource "azurerm_private_dns_zone" "example" {
  for_each = toset(values(var.zone_assignments))
  name     = each.value
  resource_group_name = var.zone_rg_name
}
```

The individual Azure policies are created using a similar loop with a `foreach` property. The key part though is the `replace` function used to customize both the policy and the parameters definition:

```terraform
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
```

These policy definitions are grouped in a policy set (also known as policy initiative), which makes use of the dynamic block concept in Terraform to provide the different policy definition IDs created in the previous step. Note as well how `jsondecode` and `jsonencode` can be used to convert from string to object and vice versa:

```terraform
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
```

Lastly, the policy set assignment needs to provide the correct values for each of the parameters created for the policy definitions. For this purpose, the Terraform `for` function can be used to create a dictionary that can be then serialized and provided as value to the `parameters` attribute of the assignment resource:

```terraform
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

```    
