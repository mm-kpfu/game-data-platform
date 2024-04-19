resource "yandex_vpc_network" "game_data_platform" {
  count       = var.vpc_id ? 0 : 1
  name        = "game-data-platform-${element(var.env)}"
  description = "VPC for the entire platform infrastructure (one environment)"
}

resource "yandex_vpc_subnet" "game_data_platform" {
  count          = length(var.subnets)
  zone           = var.subnets[count.index]["zone"]
  network_id     = var.vpc_id == null ? yandex_vpc_network.game_data_platform.id : var.vpc_id
  v4_cidr_blocks = var.subnets[count.index]["v4_cidr_blocks"]
}

output "vpc" {
  value = yandex_vpc_network.game_data_platform
}

output "subnets" {
  value = yandex_vpc_subnet.game_data_platform
}
