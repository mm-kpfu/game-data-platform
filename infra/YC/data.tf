#=======================================================================================================================
# For existing vpc
#data terraform_remote_state "existing_state" {
#  backend = "s3"
#  config  = {
#    endpoints = {
#      s3 = "https://storage.yandexcloud.net"
#    }
#    bucket   = "<bucket_name>"
#    region   = "ru-central1-a"
#    key      = "<path_to_state_file_in_bucket>/<state_file_name>.tfstate"
#
#    skip_region_validation      = true
#    skip_credentials_validation = true
#  }
#}
#=======================================================================================================================

data "yandex_iam_service_account" "sa" {
  service_account_id = var.service_account_id
}
