variable "env" {
  type = string
}

# If passed, vpc will not be created, subnets will use passed vpc_id as network_id
variable "vpc_id" {
  type    = string
  default = null
}

# 1 subnet - 1 availability zone
variable "subnets" {
  type = list(object({
    zone           = string
    v4_cidr_blocks = list(string)
    name           = string
  }))
}
