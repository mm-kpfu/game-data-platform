# IAM node account name
output "node_account_name" {
  description = <<EOF
    Created IAM node account name.
  EOF
  value       = try(yandex_iam_service_account.node_account[0].name, "")
}

# IAM node account id
output "node_account_id" {
  description = <<EOF
    Created IAM node account ID.
  EOF
  value       = try(yandex_iam_service_account.node_account[0].id, "")
}

# IAM service account name
output "service_account_name" {
  description = <<EOF
    Created IAM service account name.
  EOF
  value       = try(yandex_iam_service_account.master[0].name, "")
}

# IAM service account id
output "service_account_id" {
  description = <<EOF
    Created IAM service account ID.
  EOF
  value       = try(yandex_iam_service_account.master[0].id, "")
}