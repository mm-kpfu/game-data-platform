locals {
  # Leaving 20GB space for the garbage collector to have time to remove segments.
  # Taking into account data replication, we calculate how much memory remains
  # for unique data and divide by the number of partitions
  kafka_log_retention_bytes = (var.kafka_disk_size - 20) / var.kafka_default_replication_factor / var.kafka_default_partitions * 1024 * 1024 * 1024

  # The number after the slash shows how many segments there will be per partition
  kafka_log_segment_bytes = local.kafka_log_retention_bytes / 10
}

resource "yandex_mdb_kafka_cluster" "gaming-data-cluster" {
  name        = "${var.env}-${var.project_prefix_name}-kafka"
  environment = strcontains(lower(var.env), lower("prod")) ? "PRODUCTION" : "PRESTABLE"
  network_id  = var.vpc_id
  subnet_ids  = [for s in var.subnets : s.subnet_id]

  config {
    version          = var.kafka_version
    brokers_count    = var.kafka_brokers_count
    zones            = var.kafka_zones
    assign_public_ip = var.kafka_assign_public_ip
    schema_registry  = var.kafka_schema_registry
    kafka {
      resources {
        resource_preset_id = var.kafka_host_preset_id
        disk_type_id       = "network-hdd"
        disk_size          = var.kafka_disk_size
      }
      kafka_config {
        compression_type           = var.kafka_compression_type
        log_retention_bytes        = can(var.kafka_log_retention_bytes) ? var.kafka_log_retention_bytes : local.kafka_log_retention_bytes
        log_segment_bytes          = can(var.kafka_log_segment_bytes) ? var.kafka_log_segment_bytes : local.kafka_log_segment_bytes
        log_retention_hours        = 168
        # log_preallocate            = true
        num_partitions             = var.kafka_default_partitions
        default_replication_factor = var.kafka_default_replication_factor
        message_max_bytes          = 1048576
        replica_fetch_max_bytes    = 1048576
        ssl_cipher_suites          = [
          "TLS_DHE_RSA_WITH_AES_128_CBC_SHA", "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256"
        ]
        offsets_retention_minutes = 10080
        sasl_enabled_mechanisms   = ["SASL_MECHANISM_SCRAM_SHA_256", "SASL_MECHANISM_SCRAM_SHA_512"]
      }
    }
  }
}

resource "yandex_mdb_kafka_topic" events {
  count              = length(var.kafka_topics)
  cluster_id         = yandex_mdb_kafka_cluster.gaming-data-cluster.id
  name               = var.kafka_topics[count.index]["topic_name"]
  partitions         = var.kafka_topics[count.index]["partitions"] == null ? var.kafka_default_partitions : var.kafka_topics[count.index]["partition"]
  replication_factor = var.kafka_topics[count.index]["replication_factor"] == null ? var.kafka_default_replication_factor : var.kafka_topics[count.index]["replication_factor"]
}

resource "yandex_mdb_kafka_user" "kafka_user" {
  count      = length(var.kafka_users)
  cluster_id = yandex_mdb_kafka_cluster.gaming-data-cluster.id
  name       = var.kafka_users[count.index]["name"]
  password   = var.kafka_users[count.index]["password"]

  dynamic "permission" {
    for_each = var.kafka_users[count.index]["permissions"]
    content {
      topic_name  = permission.value["topic_name"]
      role        = permission.value["role"]
      allow_hosts = permission.value["allow_hosts"]
    }
  }
}

