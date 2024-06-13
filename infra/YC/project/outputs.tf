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

output "flink_availability_zones" {
  value = [for loc in var.locations: loc.zone]
}

output "name_prefix" {
  value = var.name_prefix
}

output "kafka_enabled" {
  value = var.kafka_enabled
}

output "kafka_users" {
  sensitive = true
  value = length(module.kafka) > 0 ? module.kafka[0].users: []
}

output "kafka_topics" {
  value = length(module.kafka) > 0 ? module.kafka[0].topics: []
}

output "kafka_hosts" {
  value = length(module.kafka) > 0 ? module.kafka[0].hosts: {}
}

output "clickhouse_enabled" {
  value = var.clickhouse_enabled
}

output "clickhouse_hosts" {
  value = length(module.Clickhouse) > 0 ? module.Clickhouse[0].cluster_fqdns_list : []
}

output "clickhouse_users" {
  sensitive = true
  value = length(module.Clickhouse) > 0 ? module.Clickhouse[0].cluster_users : []
}

output "clickhouse_databases" {
  value = length(module.Clickhouse) > 0 ? module.Clickhouse[0].databases : []
}
