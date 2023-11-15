output "verified_access_group_ids" {
  value = {for group_name, values in awscc_ec2_verified_access_group.main: group_name => values["verified_access_group_id"]}
}
