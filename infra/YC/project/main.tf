terraform {
  required_version = ">= 1.0.0"
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  # put values here or create a .conf file
  backend "s3" {
    #  endpoints = {
    #    s3 = "https://storage.yandexcloud.net"
    #  }
    #  bucket     = ""
    #  region     = ""
    #  key        = ""
    #  access_key = ""
    #  secret_key = ""
    #  skip_region_validation      = true # Required for YC!
    #  skip_credentials_validation = true # Required for YC!
    #  skip_requesting_account_id  = true # Required for YC!
  }
}

provider "yandex" {
  zone = "ru-central1-a"
}

locals {
  # To get vpc data from a remote state, uncomment "data.terraform_remote_state.existing_state.vpc_id," and
  # "data.terraform_remote_state.existing_state" in "data.tf" file
  vpc_id       = var.vpc.id   != null ? var.vpc.id : try(/*data.terraform_remote_state.existing_state.vpc_id,*/ null)
  network_name = var.vpc.name != null ? var.vpc.name : try(/*data.terraform_remote_state.existing_state.vpc_name,*/ "game-data-platform")
  zones = {
    ru-central1-a = ["10.0.0.0/16"]
    ru-central1-b = ["10.1.0.0/16"]
    ru-central1-d = ["10.2.0.0/16"]
  }


  management_location = try(tolist(setsubtract(keys(local.zones), [for loc in var.locations : loc.zone]))[0], null)

  # If 2 availability zones are specified for a k8s cluster or kafka,
  # then YC will create a master node or zookeeper in each availability zone, so another network is added
  locations = [
    for l in length(var.locations) != 2 ? var.locations : flatten([
      var.locations, {
        zone = local.management_location, v4_cidr_blocks = local.zones[local.management_location]
      }
    ]) : merge(l, { name : "${var.name_prefix}-${l.zone}" })
  ]
  created_subnets = [
    for key, value in module.network.private_subnets : {
      subnet_id = value.subnet_id
      zone      = value.zone
    }
  ]

  node_groups_with_subnets = flatten([
    for node_group in var.node_groups : (
      strcontains(node_group.name, "flink") == false ? [merge(
      node_group, {
        node_locations = [for s in local.created_subnets : s if contains(node_group.node_locations, s.zone)]
      })] : [
      for s in local.created_subnets : merge(node_group, {
        name           = "${node_group.name}-${s.zone}",
        node_taints    = flatten([lookup(node_group, "node_taints", []), "zone=${s.zone}:NoSchedule"]),
        node_locations = [s],
      })
    ]
    )
  ]
  )

  node_groups_with_placements = [
    for node_group in local.node_groups_with_subnets : merge(
      node_group,
      {
        placement_group_id = [
          for p in yandex_compute_placement_group.k8s_nodes : p.id if length(node_group.node_locations) == 1 && "${var.name_prefix}-${node_group.node_locations[0].zone}" == p.name
        ][0]
      }
    )
  ]

  final_node_groups = {
    for node_group in local.node_groups_with_placements: node_group.name => node_group
  }

  k8s_cidr_blocks = {
    cluster_cidr = "10.3.0.0/16",
    service_cidr = "10.4.0.0/16"
  }
}

module "network" {
  source          = "git@github.com:terraform-yc-modules/terraform-yc-vpc.git"
  create_vpc      = local.vpc_id == null ? true : false
  vpc_id          = local.vpc_id
  network_name = local.network_name
  # add cidr blocks if empty
  private_subnets = [
    for loc in local.locations :
    (lookup(loc, "v4_cidr_blocks", null) != null ? loc : merge(loc, { v4_cidr_blocks = local.zones[loc.zone] }))
  ]
}

# module "kafka" {
#   source                           = "../modules/managedKafka"
#   env                              = var.kafka_env
#   subnets                          = local.created_subnets
#   vpc_id                           = module.network.vpc_id
#   kafka_topics                     = var.kafka_topics
#   kafka_users                      = var.kafka_users
#   kafka_default_replication_factor = var.kafka_default_replication_factor
#   project_prefix_name              = var.name_prefix
#   kafka_brokers_count              = var.kafka_brokers_count
#   kafka_compression_type           = var.kafka_compression_type
#   kafka_zones                      = [for loc in var.locations : loc.zone]
#   kafka_version                    = var.kafka_version
#   kafka_assign_public_ip           = var.kafka_assign_public_ip
#   kafka_log_segment_bytes          = var.kafka_log_segment_bytes
#   kafka_log_retention_bytes        = var.kafka_log_retention_bytes
#   kafka_schema_registry            = var.kafka_schema_registry
#   kafka_disk_size                  = var.kafka_disk_size
#   kafka_host_preset_id             = var.kafka_host_preset_id
#   kafka_default_partitions         = var.kafka_default_partitions
# }

resource "yandex_compute_placement_group" "k8s_nodes" {
  count                         = length(var.locations)
  name                          = "${var.name_prefix}-${local.locations[count.index].zone}"
  placement_strategy_partitions = 5
}

resource "time_sleep" "wait_for_iam" {
  create_duration = "5s"
  depends_on      = [
    yandex_resourcemanager_folder_iam_member.sa_calico_network_policy_role,
    yandex_resourcemanager_folder_iam_member.sa_cilium_network_policy_role,
    yandex_resourcemanager_folder_iam_member.sa_node_group_public_role_admin,
    yandex_resourcemanager_folder_iam_member.node_account
  ]
}

module "KubernetesCluster" {
  source                      = "../modules/managedKubernetes"
  network_id                  = module.network.vpc_id
  cluster_name                = var.name_prefix
  master_locations            = local.created_subnets
  node_groups                 = local.final_node_groups
  public_access               = var.master_public_access
  release_channel             = "STABLE"
  allow_public_load_balancers = false
  master_service_account_id   = var.use_existing_sa ? var.master_service_account_id : yandex_iam_service_account.master[0].id
  node_service_account_id     = var.use_existing_sa ? var.node_service_account_id : yandex_iam_service_account.node_account[0].id
  create_kms                  = true
  kms_key                     = { name = "k8s-flink" }
  enable_outgoing_traffic     = var.enable_outgoing_traffic
  folder_id                   = var.folder_id
  cluster_ipv4_range          = local.k8s_cidr_blocks.cluster_cidr
  service_ipv4_range          = local.k8s_cidr_blocks.service_cidr
  name_prefix                 = var.name_prefix

  depends_on = [
    yandex_resourcemanager_folder_iam_member.node_account,
    yandex_resourcemanager_folder_iam_member.sa_calico_network_policy_role,
    yandex_resourcemanager_folder_iam_member.sa_cilium_network_policy_role,
    yandex_resourcemanager_folder_iam_member.sa_node_group_public_role_admin,
    time_sleep.wait_for_iam
  ]
}
