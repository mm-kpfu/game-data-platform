#=======================================================================================================================
# For existing vpc

data terraform_remote_state "existing_state" {
  count = var.use_remote_state ? 1 : 0
  backend = "s3"
  config = {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = var.existing_state_conf.bucket
    region = var.existing_state_conf.region
    key    = var.existing_state_conf.key

    skip_region_validation = true # Required for YC!
    skip_credentials_validation = true # Required for YC!
    skip_requesting_account_id = true # Required for YC!
    access_key = var.access_key
    secret_key = var.secret_key
  }
}
#=======================================================================================================================
