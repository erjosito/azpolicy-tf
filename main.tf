terraform {
  # Update this block with the location of your terraform state file
  backend "azurerm" {
    resource_group_name  = "erjositotfstate"
    storage_account_name = "erjositotfstate"
    container_name       = "dnszonegrouppolicy"
    key                  = "dnszonegrouppolicy.tfstate"
  }
}

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