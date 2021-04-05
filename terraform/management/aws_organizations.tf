#################################################
# Fetching Data of AWS Organizations
#################################################

data "aws_organizations_organization" "this" {}

data "aws_organizations_organizational_units" "first" {
  parent_id = data.aws_organizations_organization.this.roots[0].id
}

#################################################
# SCP: Deny Cloudtrail Write
#################################################

resource "aws_organizations_policy" "deny_cloudtrail" {
  name = "DenyCloudtrailWrite"

  content = data.aws_iam_policy_document.deny_cloudtrail.json
  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "deny_cloudtrail" {
  statement {
    effect = "Deny"
    actions = [
      "cloudtrail:DeleteTrail",
      "cloudtrail:StopLogging",
      "cloudtrail:UpdateTrail",
    ]
    resources = [
      "*"
    ]
  }

  /*
  statement {
    effect = "Deny"
    actions = [
      "s3:DeleteObject",
    ]
    resources = [
      "${data.terraform_remote_state.audit.outputs.cloudtrail_bucket_arn}/*"
    ]
  }
  */
}

resource "aws_organizations_policy_attachment" "deny_cloudtrail" {
  policy_id = aws_organizations_policy.deny_cloudtrail.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

#################################################
# SCP: Deny Using Access Keys
#################################################

resource "aws_organizations_policy" "deny_access_key" {
  name = "DenyUsingAccessKey"

  content = data.aws_iam_policy_document.deny_access_key.json
  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "deny_access_key" {
  statement {
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:UpdateAccessKey",
      "iam:CreateAccessKey",
      "iam:ListAccessKeys",
    ]
    resources = [
      "*"
    ]
  }
}

locals {
  deny_access_key_targets = [for v in tolist(data.aws_organizations_organizational_units.first.children) : v.id if v.name == "Service"]
}

resource "aws_organizations_policy_attachment" "deny_access_key" {
  for_each = toset(local.deny_access_key_targets)

  policy_id = aws_organizations_policy.deny_access_key.id
  target_id = each.value
}

#################################################
# SCP: Deny Shutting Organization Access Out
#################################################

resource "aws_organizations_policy" "deny_shut_out" {
  name = "DenyShuttingOrganizationAccessOut"

  content = data.aws_iam_policy_document.deny_shut_out.json
  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "deny_shut_out" {
  statement {
    effect = "Deny"
    actions = [
      "iam:Add*",
      "iam:Attach*",
      "iam:Create*",
      "iam:Delete*",
      "iam:Put*",
      "iam:Remove*",
      "iam:Update*",
    ]
    resources = [
      "arn:aws:iam::*:role/OrganizationAccountAccessRole",
      "arn:aws:iam::*:role/aws-reserved/sso.amazonaws.com/ap-northeast-1/AWSReservedSSO_*",
    ]
  }
}

locals {
  deny_shut_out_targets = [for v in tolist(data.aws_organizations_organizational_units.first.children) : v.id if v.name == "Sandbox"]
}

resource "aws_organizations_policy_attachment" "deny_shut_out" {
  for_each = toset(local.deny_shut_out_targets)

  policy_id = aws_organizations_policy.deny_shut_out.id
  target_id = each.value
}

#################################################
# SCP: Deny Any Actions
#################################################

resource "aws_organizations_policy" "deny_any" {
  name = "DenyAnyActions"

  content = data.aws_iam_policy_document.deny_any.json
  lifecycle {
    prevent_destroy = true
  }
}

data "aws_iam_policy_document" "deny_any" {
  statement {
    effect = "Deny"
    actions = [
      "*",
    ]
    resources = [
      "*",
    ]
  }
}

locals {
  deny_any_targets = [for v in tolist(data.aws_organizations_organizational_units.first.children) : v.id if v.name == "Trash"]
}

resource "aws_organizations_policy_attachment" "deny_any" {
  for_each = toset(local.deny_any_targets)

  policy_id = aws_organizations_policy.deny_shut_out.id
  target_id = each.value
}
