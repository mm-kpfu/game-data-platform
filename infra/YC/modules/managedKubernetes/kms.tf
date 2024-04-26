locals {
  kms_name        = lookup(var.kms_key, "name", "${var.name_prefix}-${var.master_locations[0].zone}")
  kms_key_with_id = "${local.kms_name}-${random_string.unique_id.result}"
}

resource "yandex_kms_symmetric_key" "kms_key" {
  count             = var.create_kms ? 1 : 0
  folder_id         = local.folder_id
  name              = local.kms_key_with_id
  description       = lookup(var.kms_key, "description", "K8S KMS symetric key")
  default_algorithm = lookup(var.kms_key, "default_algorithm", "AES_256")
  rotation_period   = lookup(var.kms_key, "rotation_period", "8760h")
}
