# DNS Zone Group module

This module creates Private DNS Zones and Azure Policies to automatically connect private endpoints of certain types to the corresponding private DNS zone. The private DNS zones and private endpoint types are specified through an input dictionary (map) variable, where the keys are the endpoint types, and the values the private zone as documented in [Azure services DNS configuration](https://learn.microsoft.com/azure/private-link/private-endpoint-dns#azure-services-dns-zone-configuration). For example:

```
"blob" = "privatelink.blob.core.windows.net"
"file" = "privatelink.file.core.windows.net"
"table" = "privatelink.table.core.windows.net"
"queue" = "privatelink.queue.core.windows.net"
```

The module will iterate over this variable and do the following:

- Create private DNS zones for each value (the resource group is provided by means of an additional variable)
- Create Azure Policy definitions for each item
- Group the individual definitions in a single policy set (aka initiative)
- Create the assignment for the policy set, and supply the DNS zone names as parameters.

## Issues

- Some private endpoints require connecting to multiple private zones, such as App services `sites`, who need to connect to `privatelink.azurewebsites.net` and `scm.privatelink.azurewebsites.net`. Fixing this would require changing the structure of the `zone-assignments` variable.
- Some private endpoints require connecting to a private zone whose name is not predictable, either because is random or because it includes the region name.

## Sample usage

```terraform
module "dns-zone-group" {
  source = "./modules/dns-zone-group"
  definition_management_group = "/providers/Microsoft.Management/managementGroups/mymgmtgroup"
  assignment_location = "eastus2"
  zone_rg_name = "dns"
  zone_assignments = {
    "blob" = "privatelink.blob.core.windows.net"
    "file" = "privatelink.file.core.windows.net"
    "table" = "privatelink.table.core.windows.net"
    "queue" = "privatelink.queue.core.windows.net"
  }
}
```

## Argument reference

- `definition_management_group`: full ARM ID of the Management Group where the policies, initiative and assignment will be created.
- `assignment location`: DINE policies need a location for the Managed System Identity used to deploy the zone group
- `zone_rg_name`: the private DNS zones will be created in this resource group
- `zone_assignments`: map-type variable with the private endpoint types (group IDs in private link terminology) and the private DNS zones they should be associated to via zone groups.

## Output reference

- `policyAsignmentOutput`: output for the policy assignment operation.
