#========================================================COMMON=========================================================
variable "name_prefix" {
  description = "all resources will be created with this prefix"
  default     = "gdp"
}

variable "existing_state_conf" {
  type = object({
    bucket = string
    key    = string
    region = optional(string)
  })

  default = {
    bucket = null
    key    = null
    region = null
  }
}

variable "folder_id" {
  type = string
}

# for using outputs from remote state
variable "use_remote_state" {
  default = false
}
variable "access_key" {
  default = null
}
variable "secret_key" {
  default = null
}

#======================================================Kubernetes=======================================================
variable "use_existing_sa" {
  description = "If not true, then new users will be created, else you need to specify and service_account_id"
  type        = bool
  default     = false
}

variable "master_service_account_id" {
  type = string
}

variable "node_service_account_id" {
  type = string
}

variable "master_location" {
  description = "zone name or 'regional'"
  default = "ru-central1-a"
}

variable "enable_cilium_policy" {
  description = "Flag for enabling or disabling Cilium CNI."
  type        = bool
  default     = false
}

# Kubernetes Master node common parameters
variable "master_public_access" {
  description = "Public or private Kubernetes cluster"
  type        = bool
  default     = true
}

variable "security_groups_ids_list" {
  type     = list(string)
  default  = []
  nullable = true
}

variable "node_groups" {
  type = any
  default = [
    {
      name = "flink-common"
      auto_scale = {
        min     = 1
        max     = 10
        initial = 1
      },
      node_labels = {
        node_group = "flink"
      }
    },

    {
      name = "superset"
      node_locations = [
        {
          zone = "ru-central1-a",
        }
      ],
      node_labels = {
        node_group = "superset"
      },
      node_taints = ["node_group=superset-only:NoSchedule"]
    }
  ]
}

variable "enable_default_rules" {
  default = true
}

variable "custom_ingress_rules" {
  description = <<-EOF
    Map definition of custom security ingress rules.

    Example:
    ```
    {
      "rule1" = {
        protocol = "TCP"
        description = "rule-1"
        v4_cidr_blocks = ["0.0.0.0/0"]
        from_port = 3000
        to_port = 32767
      },
      "rule2" = {
        protocol = "TCP"
        description = "rule-2"
        v4_cidr_blocks = ["0.0.0.0/0"]
        port = 443
      },
      "rule3" = {
        protocol = "TCP"
        description = "rule-3"
        predefined_target = "self_security_group"
        from_port         = 0
        to_port           = 65535
      }
    }
    ```
  EOF
  type        = any
  default = {}
}
#=======================================================NETWORK=========================================================
# It is possible to integrate into an existing network through an explicit value or both id and remote state.
# Check data.tf. If remote state and this variable is not set, vpc will be created automatically
variable "vpc" {
  type = object({
    id   = number
    name = number
  })
  default = {
    id   = null
    name = null
  }
}

variable "locations" {
  type = list(object({
    zone           = string
    v4_cidr_blocks = optional(list(string))
  }))

  # By default following cidr blocks will be used:
  # 10.0.0.0/20
  # 10.1.0.0/20
  # 10.2.0.0/20
  default = [
    {
      zone = "ru-central1-a"
    },
#     {
#       zone = "ru-central1-b"
#     }
  ]
}

variable "create_load_balancer_ip" {
  default = true
}

#=========================================================KAFKA=========================================================
variable "kafka_enabled" {
  default = true
}

variable "kafka_topics" {
  type = list(object({
    topic_name         = string
    partitions         = optional(number)
    replication_factor = optional(number)
  }))

}

variable "kafka_users" {
  type = list(object({
    name        = string
    password    = string
    permissions = list(object({
      topic_name  = string
      role        = string
      allow_hosts = optional(list(string))
    }))
  }))
}

variable "kafka_env" {
  type    = string
  default = "PRODUCTION"
}

variable "kafka_default_partitions" {
  type    = number
  default = 20
}

variable "kafka_default_replication_factor" {
  type    = number
  default = 1
}

variable "kafka_brokers_count" {
  type    = number
  default = 1
}

variable "kafka_host_preset_id" {
  default = "s2.small"
}

variable "kafka_disk_size" {
  type    = number
  default = 128
}

variable "kafka_schema_registry" {
  type    = bool
  default = false
}

variable "kafka_log_retention_bytes" {
  # if not specified, it is calculated automatically in kafka.tf
  type    = number
  default = null
}

variable "kafka_log_segment_bytes" {
  # if not specified, it is calculated automatically in kafka.tf
  type    = number
  default = null
}

variable "kafka_compression_type" {
  type    = string
  #  If the servers from which the data comes are located in the same cloud (Yandex Cloud),
  #  it would be best not to use compression, since the internal network is not charged and
  #  the path producer -> broker -> consumer is short. Otherwise, computing costs will
  #  increase as compression uses CPU as well and the delay will also increase.
  default = "COMPRESSION_TYPE_UNCOMPRESSED"
}

variable "kafka_version" {
  type    = string
  default = "3.5"
}

variable "kafka_assign_public_ip" {
  # if game servers located outside of vpc
  default = false
}

variable "create_default_kafka_user" {
  type = bool
  default = true
}
#=====================================================Clickhouse========================================================
variable "clickhouse_enabled" {
  default = true
}

variable "clickhouse_databases" {
  type = list(object({
    name = string
  }))

  default = [
    {
      name = "gdp"
    }
  ]
}

variable "clickhouse_config" {
  type = any
  default = null
}

variable "clickhouse_users" {
  type = list(any)
}

variable "clickhouse_hosts" {
  type = list(any)
}

variable "clickhouse_disk_type_id" {}
variable "clickhouse_disk_size" {}
variable "clickhouse_resource_preset_id" {}

variable "create_default_clickhouse_user" {
  type = bool
  default = true
}
variable "clickhouse_async_insert_default_user" {
  type = bool
  default = false
}
