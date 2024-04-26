locals {
  create_sa = var.use_existing_sa && var.master_service_account_id != null && var.node_service_account_id != null ? true : false
  service_account_name = "${var.name_prefix}-k8s-flink-service"
  node_account_name    = "${var.name_prefix}-k8s-flink-node"
}

resource "yandex_iam_service_account" "master" {
  count = var.use_existing_sa ? 0 : 1
  name  = local.service_account_name
}

resource "yandex_resourcemanager_folder_iam_member" "master" {
  count = var.use_existing_sa ? 0 : 1
  role               = "editor"
  member             = "serviceAccount:${yandex_iam_service_account.master[0].id}"
  folder_id          = var.folder_id
}

resource "yandex_iam_service_account" "node_account" {
  count     = var.use_existing_sa ? 0 : 1
  name      = local.node_account_name
}

resource "yandex_resourcemanager_folder_iam_member" "node_account" {
  count     = var.use_existing_sa ? 0 : 1
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.node_account[0].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_node_group_public_role_admin" {
  count     = anytrue([for i, v in var.node_groups : lookup(v, "nat", false)]) && !local.create_sa ? 1 : 0
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.master[0].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_cilium_network_policy_role" {
  count     = var.enable_cilium_policy && !local.create_sa ? 1 : 0
  folder_id = var.folder_id
  role      = "k8s.tunnelClusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.master[0].id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa_calico_network_policy_role" {
  count     = var.enable_cilium_policy || var.use_existing_sa ? 0 : 1
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  member    = "serviceAccount:${yandex_iam_service_account.master[0].id}"
}
