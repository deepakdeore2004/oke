resource "oci_core_network_security_group" "cp" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id

  #Optional
  display_name  = "${var.cluster_name}-cp"
  freeform_tags = var.freeform_tags["nsg"]
  //defined_tags = {"Operations.CostCenter"= "42"}
}

resource "oci_core_network_security_group_security_rule" "cp_egress" {
  network_security_group_id = oci_core_network_security_group.cp.id
  description               = local.cp_egress[count.index].description
  destination               = local.cp_egress[count.index].destination
  destination_type          = local.cp_egress[count.index].destination_type
  direction                 = "EGRESS"
  protocol                  = local.cp_egress[count.index].protocol

  stateless = false

  dynamic "tcp_options" {
    for_each = local.cp_egress[count.index].protocol == local.tcp_protocol && local.cp_egress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = local.cp_egress[count.index].port
        max = local.cp_egress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.cp_egress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.cp_egress)
}

resource "oci_core_network_security_group_security_rule" "cp_egress_npn" {
  network_security_group_id = oci_core_network_security_group.cp.id
  description               = "Allow Kubernetes Control plane to communicate with pods"
  destination               = data.oci_core_subnet.subnet["pods"].cidr_block
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  protocol                  = local.all_protocols

  stateless = false

  count = var.cni_type == "npn" ? 1 : 0

}

resource "oci_core_network_security_group_security_rule" "cp_ingress" {
  network_security_group_id = oci_core_network_security_group.cp.id
  description               = local.cp_ingress[count.index].description
  direction                 = "INGRESS"
  protocol                  = local.cp_ingress[count.index].protocol
  source                    = local.cp_ingress[count.index].source
  source_type               = local.cp_ingress[count.index].source_type

  stateless = false

  dynamic "tcp_options" {
    for_each = local.cp_ingress[count.index].protocol == local.tcp_protocol ? [1] : []
    content {
      destination_port_range {
        min = local.cp_ingress[count.index].port
        max = local.cp_ingress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.cp_ingress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.cp_ingress)

}

resource "oci_core_network_security_group_security_rule" "cp_ingress_additional_cidrs" {
  network_security_group_id = oci_core_network_security_group.cp.id
  description               = "Allow additional CIDR block access to control plane. Required for kubectl/helm."
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = element(var.control_plane_allowed_cidrs, count.index)
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = 6443
      max = 6443
    }
  }

  count = length(var.control_plane_allowed_cidrs)

}

# workers nsg and rules
resource "oci_core_network_security_group" "workers" {
  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-workers"
  vcn_id         = var.vcn_id
}

resource "oci_core_network_security_group_security_rule" "workers_egress" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = local.workers_egress[count.index].description
  destination               = local.workers_egress[count.index].destination
  destination_type          = local.workers_egress[count.index].destination_type
  direction                 = "EGRESS"
  protocol                  = local.workers_egress[count.index].protocol

  stateless = false

  dynamic "tcp_options" {
    for_each = local.workers_egress[count.index].protocol == local.tcp_protocol && local.workers_egress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = local.workers_egress[count.index].port
        max = local.workers_egress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.workers_egress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.workers_egress)
}

resource "oci_core_network_security_group_security_rule" "workers_egress_npn" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = "Allow worker nodes access to pods"
  destination               = data.oci_core_subnet.subnet["pods"].cidr_block
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  protocol                  = local.all_protocols

  stateless = false

  count = var.cni_type == "npn" ? 1 : 0
}

# add this rule separately so it can be controlled independently
resource "oci_core_network_security_group_security_rule" "workers_egress_internet" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = "Allow worker nodes access to Internet. Required for getting container images or using external services"
  destination               = local.anywhere
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  protocol                  = local.tcp_protocol

  stateless = false

  count = var.allow_worker_internet_access == true ? 1 : 0

}

resource "oci_core_network_security_group_security_rule" "workers_ingress" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = local.workers_ingress[count.index].description
  direction                 = "INGRESS"
  protocol                  = local.workers_ingress[count.index].protocol
  source                    = local.workers_ingress[count.index].source
  source_type               = local.workers_ingress[count.index].source_type

  stateless = false

  dynamic "tcp_options" {
    for_each = local.workers_ingress[count.index].protocol == local.tcp_protocol && local.workers_ingress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = local.workers_ingress[count.index].port
        max = local.workers_ingress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.workers_ingress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.workers_ingress)

}

# add the next 2 rules separately so it can be controlled independently based on which lbs are created
resource "oci_core_network_security_group_security_rule" "workers_ingress_from_int_lb" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = "Allow internal load balancers traffic to workers"
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = data.oci_core_subnet.subnet["lb"].cidr_block
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = local.node_port_min
      max = local.node_port_max
    }
  }
}

resource "oci_core_network_security_group_security_rule" "workers_healthcheck_ingress_from_int_lb" {
  network_security_group_id = oci_core_network_security_group.workers.id
  description               = "Allow internal load balancers health check to workers"
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = data.oci_core_subnet.subnet["lb"].cidr_block
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = local.health_check_port
      max = local.health_check_port
    }
  }
}

# pod nsg and rules
resource "oci_core_network_security_group" "pods" {
  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-pods"
  vcn_id         = var.vcn_id
}

resource "oci_core_network_security_group_security_rule" "pods_egress" {
  network_security_group_id = oci_core_network_security_group.pods.id
  description               = local.pods_egress[count.index].description
  destination               = local.pods_egress[count.index].destination
  destination_type          = local.pods_egress[count.index].destination_type
  direction                 = "EGRESS"
  protocol                  = local.pods_egress[count.index].protocol

  stateless = false

  dynamic "tcp_options" {
    for_each = local.pods_egress[count.index].protocol == local.tcp_protocol && local.pods_egress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = local.pods_egress[count.index].port
        max = local.pods_egress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.pods_egress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = var.cni_type == "npn" ? length(local.pods_egress) : 0
}

# add this rule separately so it can be controlled independently
resource "oci_core_network_security_group_security_rule" "pods_egress_internet" {
  network_security_group_id = oci_core_network_security_group.pods.id
  description               = "Allow pods access to Internet"
  destination               = local.anywhere
  destination_type          = "CIDR_BLOCK"
  direction                 = "EGRESS"
  protocol                  = local.tcp_protocol

  stateless = false
  count     = (var.cni_type == "npn" && var.allow_pod_internet_access == true) ? 1 : 0

}

# internal lb nsg and rules
resource "oci_core_network_security_group" "int_lb" {
  compartment_id = var.compartment_id
  display_name   = "${var.cluster_name}-int-lb"
  vcn_id         = var.vcn_id

  count = 1
}

resource "oci_core_network_security_group_security_rule" "int_lb_egress" {
  network_security_group_id = oci_core_network_security_group.int_lb[0].id
  description               = local.int_lb_egress[count.index].description
  destination               = local.int_lb_egress[count.index].destination
  destination_type          = local.int_lb_egress[count.index].destination_type
  direction                 = "EGRESS"
  protocol                  = local.int_lb_egress[count.index].protocol

  stateless = false
  # TODO: condition for end-to-end SSL/SSL termination
  dynamic "tcp_options" {
    for_each = local.int_lb_egress[count.index].protocol == local.tcp_protocol && local.int_lb_egress[count.index].port != -1 ? [1] : []
    content {
      destination_port_range {
        min = length(regexall("-", local.int_lb_egress[count.index].port)) > 0 ? tonumber(element(split("-", local.int_lb_egress[count.index].port), 0)) : local.int_lb_egress[count.index].port
        max = length(regexall("-", local.int_lb_egress[count.index].port)) > 0 ? tonumber(element(split("-", local.int_lb_egress[count.index].port), 1)) : local.int_lb_egress[count.index].port
      }
    }
  }

  dynamic "icmp_options" {
    for_each = local.int_lb_egress[count.index].protocol == local.icmp_protocol ? [1] : []
    content {
      type = 3
      code = 4
    }
  }

  count = length(local.int_lb_egress)
}

resource "oci_core_network_security_group_security_rule" "int_lb_ingress" {
  network_security_group_id = oci_core_network_security_group.int_lb[0].id
  description               = "Allow stateful ingress from ${element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 0)} on port ${element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)}"
  direction                 = "INGRESS"
  protocol                  = local.tcp_protocol
  source                    = element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 0)
  source_type               = "CIDR_BLOCK"

  stateless = false

  tcp_options {
    destination_port_range {
      min = length(regexall("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1))) > 0 ? element(split("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)), 0) : element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)
      max = length(regexall("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1))) > 0 ? element(split("-", element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)), 1) : element(element(local.internal_lb_allowed_cidrs_and_ports, count.index), 1)
    }
  }

  count = length(local.internal_lb_allowed_cidrs_and_ports)
}
