variable "project_prefix_name" {
  default = "gdp"
}

variable "subnets" {
  type = list(object({
    subnet_id   = string
    zone = string
  }))
}

variable "vpc_id" {
  type = string
}

variable "env" {
  type = string
}

variable "security_group_ids" {
  default = []
}

variable "kafka_topics" {
  type = list(object({
    topic_name         = string
    partitions         = optional(number)
    replication_factor = optional(number)
  }))
}

variable "kafka_default_partitions" {
  type    = number
  default = 20
}

variable "kafka_default_replication_factor" {
  type    = number
  default = 2
}

variable "kafka_brokers_count" {
  type    = number
  default = 2
}

variable "kafka_host_preset_id" {
  default = "s2.small"
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
}

variable "kafka_assign_public_ip" {
  # if game servers located outside of vpc
  default = false
}

variable "kafka_version" {
  type    = string
  default = "3.5"
}

variable "kafka_zones" {
  type = list(string)
}
