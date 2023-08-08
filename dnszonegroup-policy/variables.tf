variable "definition_management_group" {
  type        = string
  description = "Management group where policies and initiatives are defined"
}
variable "endpoint_types" {
  type        = list(string)
  description = "List of endpoint types to create policies for"
  default     = ["blob", "table", "queue", "file"]
}
variable "zone_subscription_id" {
  type        = string
  description = "Subscription ID where the private DNS zones are located"
  default     = ""
}
variable "zone_rg_name" {
  type        = string
  description = "Name of the private DNS zone resource group"
  default     = "zone-rg"
}
variable "zone_assignments" {
  type        = map(string)
  description = "Map of endpoint types to private DNS zone IDs"
  default = {
    "blob" = "privatelink.blob.core.windows.net"
    "file" = "privatelink.file.core.windows.net"
    "table" = "privatelink.table.core.windows.net"
    "queue" = "privatelink.queue.core.windows.net"
  }
}
variable "initiative_param_template" {
  type = string
  description = "JSON Template for creating initiative parameters"
  default = <<PARAM_TEMPLATE
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
variable "assignment_msi_roles" {
  type        = set(string)
  description = "Azure RBAC Role Names required for DINE policy MSI. Can specify multiple RBAC roles as a set."
  default     = [ "Network Contributor" ]
}
variable "assignment_location" {
  type        = string
  description = "A location is required when specifying the identity for DINE."
  default     = "eastus2"
}