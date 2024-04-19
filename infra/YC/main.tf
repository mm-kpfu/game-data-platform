terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"

#  backend "s3" {
#    endpoints = {
#      s3 = "https://storage.yandexcloud.net"
#    }
#    bucket = "<bucket_name>"
#    region = "ru-central1"
#    key    = "<path_to_state_file_in_bucket>/<state_file_name>.tfstate"
#
#    skip_region_validation      = true
#    skip_credentials_validation = true
#    skip_requesting_account_id  = true
#    # This option is required to describe backend for Terraform version 1.6.1 or higher.
#    skip_s3_checksum            = true
#  }
}

provider "yandex" {
  zone = "ru-central1-a"
}

module "network" {
  source = "https://gitlab.com/MarselMuzafarov/game-data-platform"
  env = var.env
  subnets = var.subnets
}

#module "kafka" {
#  source = "./modules/managedKafka"
#  env = var.env
#  subnets = [for s in var.subnets : s if strcontains(lower(s.name), lower("kafka"))]
#  project_prefix_name = var.name_prefix
#  vpc_id = local.vpc_id
#  kafka_topics = var.kafka_topics
#  kafka_users = var.kafka_users
#}

