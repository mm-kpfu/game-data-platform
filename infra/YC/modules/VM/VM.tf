resource "yandex_compute_placement_group" "placement_group" {
  name                          = var.placement_group.name
  folder_id                     = var.placement_group.folder_id
  description                   = var.placement_group.description
  placement_strategy_partitions = var.placement_group.placement_strategy_partitions
}

resource "yandex_compute_instance_group" "flink_standard_cluster" {
  count              = length(var.instance_groups)
  service_account_id = var.service_account_id
  folder_id          = var.instance_groups.folder_id

  instance_template {
    platform_id = var.instance_groups.groups[count.index].platform_id

    boot_disk {
      initialize_params {
        size     = var.instance_groups.groups[count.index].disk_size
        type     = var.instance_groups.groups[count.index].disk_type
        image_id = var.instance_groups.groups[count.index].image_id
      }
    }

    network_interface {
      network_id = var.vpc_id
      subnet_ids = [for s in var.subnets : s.id if strcontains(s.name, "flink")]
    }

    resources {
      cores  = var.instance_groups.groups[count.index].cores
      memory = var.instance_groups.groups[count.index].memory
      gpus   = var.instance_groups.groups[count.index].gpus
    }

    placement_policy {
      placement_group_id = var.placement_group
    }
  }

  deploy_policy {
    max_expansion   = 0
    max_unavailable = 0
  }

  allocation_policy {
    zones = []
  }

  scale_policy {}
}
