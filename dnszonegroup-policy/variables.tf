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
variable "zone_id_prefix" {
  type        = string
  description = "Prefix for the private DNS zone ID, including subscription ID and resource group name"
  default     = "/subscriptions/${var.zone_subscription_id}/resourceGroups/${var.zone_rg_name}/providers/Microsoft.Network/privateDnsZones/"
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