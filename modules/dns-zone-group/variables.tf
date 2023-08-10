variable "definition_management_group" {
  type        = string
  description = "Management group where policies and initiatives are defined"
}
variable "zone_rg_name" {
  type        = string
  description = "Name of the private DNS zone resource group"
  default     = "private-dns-zone-rg"
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