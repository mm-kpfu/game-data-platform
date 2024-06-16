resource "random_string" "unique_id" {
  length = 8
}

resource "yandex_vpc_security_group" "k8s_main_sg" {
  count       = var.enable_default_rules ? 1 : 0
  folder_id   = var.folder_id
  name        = "k8s-security-main-${random_string.unique_id.result}"
  description = "K8S security group"
  network_id  = module.network.vpc_id

  ingress {
    protocol          = "TCP"
    description       = "Rule allows availability checks from load balancer's address range. It is required for the operation of a fault-tolerant cluster and load balancer services."
    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol          = "ANY"
    description       = "Rule allows master-node and node-node communication inside a security group."
    predefined_target = "self_security_group"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol       = "ANY"
    description    = "Rule allows pod-pod and service-service communication inside a security group. Indicate your IP ranges."
    v4_cidr_blocks = [local.k8s_cidr_blocks.cluster_cidr, local.k8s_cidr_blocks.service_cidr]
    from_port      = 0
    to_port        = 65535
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow access to Kubernetes API via port 6443 from subnet."
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 6443
  }

  ingress {
    protocol       = "TCP"
    description    = "Allow access to Kubernetes API via port 443 from subnet."
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 443
  }

  ingress {
    protocol = "TCP"
    port = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ICMP"
    description    = "Rule allows debugging ICMP packets from internal subnets."
    v4_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 30000
    to_port        = 32767
  }

  egress {
    protocol          = "ANY"
    description       = "Rule allows master-node and node-node communication inside a security group."
    v4_cidr_blocks    = ["0.0.0.0/0"]
    from_port         = 0
    to_port           = 65535
  }
}


resource "yandex_vpc_security_group" "clickhouse_k8s" {
  count      = var.enable_default_rules ? 1 : 0
  network_id = module.network.vpc_id
  folder_id  = var.folder_id
  name       = "${var.name_prefix}-kubernetes-to-clickhouse-${random_string.unique_id.result}"

  ingress {
    protocol = "TCP"
    security_group_id = yandex_vpc_security_group.k8s_main_sg[0].id
    port = 8123
  }

  ingress {
    protocol = "TCP"
    security_group_id = yandex_vpc_security_group.k8s_main_sg[0].id
    port = 8443
  }

  ingress {
    protocol = "TCP"
    security_group_id = yandex_vpc_security_group.k8s_main_sg[0].id
    port = 9000
  }
}

resource "yandex_vpc_security_group" "kafka_k8s" {
  count      = var.enable_default_rules ? 1 : 0
  network_id = module.network.vpc_id
  folder_id  = var.folder_id
  name       = "${var.name_prefix}-kubernetes-to-kafka-${random_string.unique_id.result}"

  ingress {
    protocol = "TCP"
    security_group_id = yandex_vpc_security_group.k8s_main_sg[0].id
    port = 9091
  }

  ingress {
    protocol = "TCP"
    security_group_id = yandex_vpc_security_group.k8s_main_sg[0].id
    port = 9092
  }
}
