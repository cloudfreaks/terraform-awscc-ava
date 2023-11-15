variable "fips_enabled" {
  type        = bool
  description = "(Optional) Indicates whether FIPS is enabled."
  default     = false
}

variable "cloudwatch_logs_enabled" {
  type        = bool
  description = "Enable Cloudwatch logging, it will automatically create the log group name based on this deployment tags."
  default     = false
}

variable "cloudwatch_loggroup_retention_in_days" {
  type        = number
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default     = 30
}

variable "policy_reference_name" {
  type        = string
  description = "(Optional) The identifier to be used when working with policy rules."
}

variable "ava_kms_enabled" {
  type        = bool
  description = "(Optional) Whether to encrypt the policy with the provided key or disable encryption."
  default     = false
}

variable "ava_kms_alias" {
  type        = string
  description = "(Optional) The alias for the KMS key, requires ava_kms_enabled to be true."
  default     = null
}

variable "groups_definition_map" {
  type        = map(string)
  description = <<EOF
  A map having the group name as key and the policy definition, if any, as value.
  Important: make sure the policy name matches the variable `policy_reference_name`.
  Example of one group having a policy and a second with no policy:
groups_definition_map = {
  "open"  = <<-EOT
    permit(principal,action,resource)
    when {
        context.<you_provider_policy_reference_name_here>.user.email.address like "*@domain.com"
    };
  EOT
  "group2" = ""
}
  EOF
}
