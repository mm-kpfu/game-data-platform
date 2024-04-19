# Main variables. For more detailed settings, go to the corresponding files


#========================================================COMMON=========================================================
variable "env" {
  type    = string
  default = "dev"  # dev, stage, prod
}

variable "name_prefix" {
  type    = string
  default = "game_data_platform"
}

variable "service_account_id" {
  type = string
}


#==========================================================VM===========================================================
#variable "placement_group" {
#  type = object({
#    name                          = string
#    folder_id                     = string
#    description                   = string
#    # Partition placement is used, since spread placement allows you to deploy
#    # no more than 5 VMs on cloud in one placement, while partition placement allows
#    # you to deploy 500 VMs in one placement
#    placement_strategy_partitions = number
#  })
#}

#variable "instance_groups" {
#  #  Several groups may be needed if you use, for example,
#  #  both analytics and ml for flows and superset for visualization
#  type = object({
#    folder_id = string
#    groups    = list(object({
#      folder_id   = string
#      disk_size   = number
#      disk_type   = string
#      image_id    = string
#      cores       = number
#      memory      = number
#      platform_id = optional(string)
#      gpus        = optional(number)
#    }))
#  })
#}

#=======================================================NETWORK=========================================================
# It is possible to integrate into an existing network through an explicit value or both id and remote state.
# Check data.tf. If remote state and this variable is not set, vpc will be created automatically
#variable "vpc_id" {
#  type    = string
#  default = null
#}
#
## 1 subnet - 1 availability zone
variable "subnets" {
  type = list(object({
    zone           = string
    v4_cidr_blocks = list(string)
    name           = string
  }))

#  # Subnet name must contain platform component name: kafka, flink, etc.
  default = [
    {
      zone           = "ru-central1-a"
      v4_cidr_blocks = ["10.5.0.0/20"]
      name           = "kafka-a"
    },
    {
      zone           = "ru-central1-a"
      v4_cidr_blocks = ["10.6.0.0/20"]
      name           = "flink-a"
    },
  ]
}


#=========================================================KAFKA=========================================================
#variable "kafka_topics" {
#  type = list(object({
#    name               = string
#    partitions         = number
#    replication_factor = number
#  }))
#}
#
#variable "kafka_default_partitions" {
#  type    = number
#  default = 20
#}
#
#variable "kafka_default_replication_factor" {
#  type    = number
#  default = 2
#}
#
#variable "kafka_brokers_count" {
#  type    = number
#  default = 2
#}
#
#variable "kafka_host_preset_id" {
#  default = "s2.small"
#}
#
#variable "kafka_users" {
#  type = list(object({
#    name        = string
#    password    = string
#    permissions = list(object({
#      topic_name  = string
#      role        = string
#      allow_hosts = optional(list(string))
#    }))
#  }))
#}
#
#variable "kafka_disk_size" {
#  type    = number
#  default = 128
#}
#
#variable "kafka_schema_registry" {
#  type    = bool
#  default = false
#}
#
#variable "kafka_log_retention_bytes" {
#  # if not specified, it is calculated automatically in kafka.tf
#  type = number
#  default = null
#}
#
#variable "kafka_log_segment_bytes" {
#  # if not specified, it is calculated automatically in kafka.tf
#  type    = number
#  default = null
#}
#
#variable "kafka_compression_type" {
#  type    = string
#  #  If the servers from which the data comes are located in the same cloud (Yandex Cloud),
#  #  it would be best not to use compression, since the internal network is not charged and
#  #  the path producer -> broker -> consumer is short. Otherwise, computing costs will
#  #  increase as compression uses CPU as well and the delay will also increase.
#  default = "COMPRESSION_TYPE_UNCOMPRESSED"
#}
#
#variable "kafka_version" {
#  type    = string
#  default = "3.5"
#}

#=========================================================FLINK=========================================================
