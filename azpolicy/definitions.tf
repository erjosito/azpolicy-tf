module "dine_dns_zone_group" {
  source              = "..//modules/definition"
  policy_name         = "dnszonegroup_dine"
  display_name        = "Create DNS Zone Group for private endpoints"
  policy_category     = "Private Link"
  management_group_id = data.azurerm_management_group.org.id
}