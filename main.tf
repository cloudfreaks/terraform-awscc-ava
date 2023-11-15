resource "awscc_ec2_verified_access_trust_provider" "main" {
  policy_reference_name           = var.policy_reference_name
  trust_provider_type             = "user"
  user_trust_provider_type        = "iam-identity-center"

  tags = [for k, v in merge(
              module.this.tags, {
                "Name" = "${module.this.id}-provider"
              }
            ): { key = k, value = v}
          ]
}

module "cloudwatch_log" {
  source  = "cloudposse/cloudwatch-logs/aws"
  version = "0.6.8"
  enabled = var.cloudwatch_logs_enabled
  name = "verifiedaccess"
  retention_in_days = var.cloudwatch_loggroup_retention_in_days
  stream_names = ["instance"]
  iam_role_enabled = false
  context = module.this.context
}

resource "awscc_ec2_verified_access_instance" "main" {
  fips_enabled           = var.fips_enabled

  logging_configurations = {
    cloudwatch_logs = {
      enabled = var.cloudwatch_logs_enabled
      log_group = module.cloudwatch_log.log_group_name
    }
  }

  verified_access_trust_provider_ids = [awscc_ec2_verified_access_trust_provider.main.verified_access_trust_provider_id]

  tags = [for k, v in merge(
              module.this.tags, {
                "Name" = "${module.this.id}-instance"
              }
            ): { key = k, value = v}
          ]
}

module "kms_key" {
  enabled = var.ava_kms_enabled
  source = "cloudposse/kms-key/aws"
  version = "0.12.1"
  description             = "KMS key for Validated Access"
  deletion_window_in_days = 7
  enable_key_rotation     = false
  alias                   = var.ava_kms_alias != "" ? "/alias/${var.ava_kms_alias}" : "/alias/ava"
}

resource "awscc_ec2_verified_access_group" "main" {
  for_each = var.groups_definition_map
  verified_access_instance_id = awscc_ec2_verified_access_instance.main.id

  policy_enabled  = each.value != "" ? true : false
  policy_document = each.value != "" ? chomp(each.value) : null

  sse_specification = var.ava_kms_enabled ? {
    customer_managed_key_enabled = true
    kms_key_arn = join("", module.kms_key[*].key_arn)
  } : null

  tags = [for k, v in merge(
              module.this.tags, {
                "Name" = "${module.this.id}-group-${each.key}"
              }
            ): { key = k, value = v}
          ]
}

data "aws_organizations_organization" "main" {}

resource "aws_ram_resource_share" "ava_group_share" {
  name                      = "${module.this.id}-ava-groups"
  allow_external_principals = false
  tags                      = module.this.tags
}

resource "aws_ram_principal_association" "principal_share_association" {
  principal          = data.aws_organizations_organization.main.arn
  resource_share_arn = aws_ram_resource_share.ava_group_share.arn
}

resource "aws_ram_resource_association" "groups_share_association" {
  for_each = awscc_ec2_verified_access_group.main
  resource_arn       = each.value.verified_access_group_arn
  resource_share_arn = aws_ram_resource_share.ava_group_share.arn
}
