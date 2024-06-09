terraform {
  required_version = ">= 1.0.0"
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  # create a .conf file
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
  # To get vpc data from a remote state
  use_existing_state = length(data.terraform_remote_state.existing_state) > 0
  vpc_id       = var.vpc.id   != null ? var.vpc.id : (local.use_existing_state ? data.terraform_remote_state.existing_state[0].outputs.vpc_id : null)
  network_name = var.vpc.name != null ? var.vpc.name : (local.use_existing_state ? data.terraform_remote_state.existing_state[0].outputs.vpc_name : "game-data-platform")
  zones = {
    ru-central1-a = ["10.0.0.0/16"]
    ru-central1-b = ["10.1.0.0/16"]
    ru-central1-d = ["10.2.0.0/16"]
  }


  management_locations = try(tolist(setsubtract(keys(local.zones), [for loc in var.locations : loc.zone])), null)

  # If 2 availability zones are specified for kafka or k8s cluster,
  # then YC will create a master node or zookeeper in each availability zone, so another network is added
  locations = [
    for l in (length(var.locations) == 3 || length(var.locations) == 1 && var.master_location != "regional") && var.kafka_brokers_count < 2 ? var.locations : flatten([
      var.locations, [for ml in local.management_locations: {
        zone = ml, v4_cidr_blocks = local.zones[ml]
      }]
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
        node_locations = [for s in local.created_subnets : s if contains([for loc in node_group.node_locations: loc.zone], s.zone)]
      })] : [
      for loc in var.locations : merge(node_group, {
        name           = "${node_group.name}-${loc.zone}",
        node_taints    = flatten([lookup(node_group, "node_taints", []), "zone=${loc.zone}:NoSchedule"]),
        node_locations = [for s in local.created_subnets: s if s.zone == loc.zone],
      })
    ]
    )
  ]
  )

  node_groups_with_placements = [
    for node_group in local.node_groups_with_subnets : merge(
      node_group,
      {
        placement_group_id = try([
          for p in yandex_compute_placement_group.k8s_nodes : p.id if length(node_group.node_locations) == 1 && "${var.name_prefix}-${node_group.node_locations[0].zone}" == p.name
        ][0], null)
      }
    )
  ]

  service_node_group = {
    name = "service-node-group"
    node_memory = 4
    node_cores = 2
    core_fraction = 100
    node_locations = [for nl in local.created_subnets: nl if contains([for l in var.locations: l.zone], nl.zone)]
    node_taints = ["CriticalAddonsOnly=true:NoSchedule"]
    node_labels = {
      node_group="service"
    }
    fixed_scale = {
      size = length(var.locations)
    }
    disk_type       = "network-hdd"
    disk_size       = 32
  }

  final_node_groups = {
    for node_group in flatten([local.node_groups_with_placements, local.service_node_group]): node_group.name => node_group
  }

  master_locations = var.master_location == "regional" ? local.created_subnets : [for s in local.created_subnets: s if s.zone == var.master_location]

  k8s_cidr_blocks = {
    cluster_cidr = "10.3.0.0/16",
    service_cidr = "10.4.0.0/16"
  }

  kafka_user = {
    name = "${var.name_prefix}-flink"
    password = null
    permissions = tolist([
      {
        role = "ACCESS_ROLE_ADMIN"
        topic_name = "*"
        allow_hosts = tolist([])
      }
    ])
  }

  final_kafka_users = var.create_default_kafka_user ? flatten([local.kafka_user, var.kafka_users]) : flatten([var.kafka_users, null])

  clickhouse_user = {
    name = "${var.name_prefix}-flink"
    password = null
    permission = [
      for dbname in var.clickhouse_databases:
      {
        database_name = dbname.name
      }
    ]
    settings = {
      async_insert = var.clickhouse_async_insert_default_user
    }
  }
  final_clickhouse_users = var.create_default_clickhouse_user ? flatten([var.clickhouse_users, local.clickhouse_user]) : flatten([var.clickhouse_users, null])
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

module "kafka" {
  count = var.kafka_enabled ? 1 : 0
  source                           = "../modules/managedKafka"
  env                              = var.kafka_env
  subnets                          = local.created_subnets
  vpc_id                           = module.network.vpc_id
  kafka_topics                     = var.kafka_topics
  kafka_users                      = [for u in local.final_kafka_users: u if u != null]
  kafka_default_replication_factor = var.kafka_default_replication_factor
  project_prefix_name              = var.name_prefix
  kafka_brokers_count              = var.kafka_brokers_count
  kafka_compression_type           = var.kafka_compression_type
  kafka_zones                      = [for loc in var.locations : loc.zone]
  kafka_version                    = var.kafka_version
  kafka_assign_public_ip           = var.kafka_assign_public_ip
  kafka_log_segment_bytes          = var.kafka_log_segment_bytes
  kafka_log_retention_bytes        = var.kafka_log_retention_bytes
  kafka_schema_registry            = var.kafka_schema_registry
  kafka_disk_size                  = var.kafka_disk_size
  kafka_host_preset_id             = var.kafka_host_preset_id
  kafka_default_partitions         = var.kafka_default_partitions
}

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
  master_locations            = local.master_locations
  node_groups                 = local.final_node_groups
  public_access               = var.master_public_access
  release_channel             = "STABLE"
  master_service_account_id   = var.use_existing_sa ? var.master_service_account_id : yandex_iam_service_account.master[0].id
  node_service_account_id     = var.use_existing_sa ? var.node_service_account_id : yandex_iam_service_account.node_account[0].id
  create_kms                  = true
  kms_key                     = { name = "${var.name_prefix}-k8s-flink" }
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

module "Clickhouse" {
  count = var.clickhouse_enabled ? 1 : 0
  source                        = "git@github.com:polina-yudina/terraform-yc-clickhouse.git"
  network_id                    = module.network.vpc_id
  name                          = "${var.name_prefix}-clickhouse"
  environment                   = "PRODUCTION"
  clickhouse_config             = var.clickhouse_config
  clickhouse_resource_preset_id = var.clickhouse_resource_preset_id
  clickhouse_disk_size          = var.clickhouse_disk_size
  clickhouse_disk_type_id       = var.clickhouse_disk_type_id
  users                         = local.final_clickhouse_users
  databases                     = var.clickhouse_databases
  hosts                         = [for host in var.clickhouse_hosts: merge(host, {subnet_id = [for s in local.created_subnets: s.subnet_id if host.zone == s.zone][0]})]
  deletion_protection           = true
}
