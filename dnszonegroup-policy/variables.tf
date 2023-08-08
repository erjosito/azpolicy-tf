variable "definition_management_group" {
  type        = string
  description = "Management group where policies and initiatives are defined"
}
variable "endpoint_types" {
  type        = list(string)
  description = "List of endpoint types to create policies for"
  default     = ["blob", "table", "queue", "file"]
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