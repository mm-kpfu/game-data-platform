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

output "kafka_users" {
  sensitive = true
  value = module.kafka.users
}

output "kafka_topics" {
  value = module.kafka.topics
}

output "kafka_hosts" {
  value = module.kafka.hosts
}

output "clickhouse_hosts" {
  value = module.Clickhouse.cluster_fqdns_list
}

output "clickhouse_users" {
  sensitive = true
  value = module.Clickhouse.cluster_users
}

output "clickhouse_databases" {
  value = module.Clickhouse.databases
}
