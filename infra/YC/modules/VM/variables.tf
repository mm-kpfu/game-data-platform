variable "placement_group" {
  type = object({
    name                          = string
    folder_id                     = string
    description                   = string
    # Partition placement is used, since spread placement allows you to deploy
    # no more than 5 VMs on cloud in one placement, while partition placement allows
    # you to deploy 500 VMs in one placement
    placement_strategy_partitions = number
  })
}

variable "instance_groups" {
  #  Several groups may be needed if you use, for example,
  #  both analytics and ml for flows and superset for visualization
  type = object({
    folder_id = string
    groups    = list(object({
      folder_id   = string
      disk_size   = number
      disk_type   = string
      image_id    = string
      cores       = number
      memory      = number
      platform_id = optional(string)
      gpus        = optional(number)
    }))
  })
}


variable "service_account_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = list(object({
    id   = string
    name = string
    zone = string
  }))
}