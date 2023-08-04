module "deny_resource_types" {
  source              = "..//modules/definition"
  policy_name         = "deny_resource_types"
  display_name        = "Deny Azure Resource types"
  policy_category     = "General"
  management_group_id = data.azurerm_management_group.org.id
}