#locals {
#  vpc_id = var.vpc_id == null ? try(data.terraform_remote_state.existing_state.outputs.vpc_id, module.network.vpc.id) : var.vpc_id
#}
