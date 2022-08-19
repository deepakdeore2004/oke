data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

# get subnet CIDRs used in egress rules
data "oci_core_subnet" "subnet" {
  for_each  = var.subnets
  subnet_id = each.value
}

data "oci_identity_availability_domains" "ad_list" {
  compartment_id = var.tenancy_id
}

data "oci_containerengine_node_pool_option" "node_pool_options" {
  node_pool_option_id = oci_containerengine_cluster.oke_cluster.id
}
