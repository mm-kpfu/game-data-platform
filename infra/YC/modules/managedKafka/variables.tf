variable "project_prefix_name" {
  type = string
}

variable "subnets" {
  type = list(object({
    id   = string
    name = string
    zone = string
  }))
}

variable "vpc_id" {
  type = string
}

variable "env" {
  type = string
}

variable "kafka_topics" {
  type = list(object({
    name               = string
    partitions         = number
    replication_factor = number
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
