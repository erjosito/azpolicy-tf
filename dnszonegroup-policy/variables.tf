variable "definition_management_group" {
  type        = string
  description = "Management group where policies and initiatives are defined"
}
variable "endpoint_types" {
  type        = list(string)
  description = "List of endpoint types to create policies for"
  default     = ["blob", "table", "queue", "file"]
}