#################################################
# Fetching Data of AWS SSO
#################################################

data "aws_ssoadmin_instances" "this" {}

data "aws_identitystore_group" "admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = "admin"
  }
}

/*
data "aws_identitystore_group" "service_dev" {
  for_each          = local.services
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  filter {
    attribute_path  = "DisplayName"
    attribute_value = each.value.developers.sso_group_name
  }
}
*/

#################################################
# Permission Sets
#################################################

resource "aws_ssoadmin_permission_set" "managed" {
  for_each     = local.managed_policy.name
  instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
  name         = each.value
}

resource "aws_ssoadmin_managed_policy_attachment" "managed" {
  for_each = local.managed_policy.name

  instance_arn       = aws_ssoadmin_permission_set.managed[each.key].instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.managed[each.key].arn

  managed_policy_arn = "${local.managed_policy.base_arn}${local.managed_policy.name.admin}"
}

#################################################
# Account assignment
#################################################

# for admin group

locals {
  admin_allowed_accounts = {
    for account in data.aws_organizations_organization.this.non_master_accounts : account.name => account if account.name != "audit"
  }
}

resource "aws_ssoadmin_account_assignment" "admin_access_to_admin_group" {
  for_each = local.admin_allowed_accounts

  instance_arn       = aws_ssoadmin_permission_set.managed["admin"].instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.managed["admin"].arn

  principal_id   = data.aws_identitystore_group.admin.id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "readonly_access_to_admin_group" {
  for_each = local.admin_allowed_accounts

  instance_arn       = aws_ssoadmin_permission_set.managed["read_only"].instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.managed["read_only"].arn

  principal_id   = data.aws_identitystore_group.admin.id
  principal_type = "GROUP"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}
