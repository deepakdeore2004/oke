locals {

  # encryption
  # dynamic group all oke clusters in a compartment
  dynamic_group_rule_all_clusters = "ALL {resource.type = 'cluster', resource.compartment.id = '${var.compartment_id}'}"

  # policy to allow dynamic group of all clusters to use kms 
  cluster_kms_policy_statement = (var.use_cluster_encryption == true && var.create_policies) ? "Allow dynamic-group ${oci_identity_dynamic_group.oke_kms_cluster[0].name} to use keys in compartment id ${var.compartment_id} where target.key.id = '${var.cluster_kms_key_id}'" : ""

  # policy to allow block volumes inside oke to use kms
  oke_volume_kms_policy_statements = (var.use_node_pool_volume_encryption == true && var.create_policies) ? [
    "Allow service oke to use key-delegates in compartment id ${var.compartment_id} where target.key.id = '${var.node_pool_volume_kms_key_id}'",
    "Allow service blockstorage to use keys in compartment id ${var.compartment_id} where target.key.id = '${var.node_pool_volume_kms_key_id}'"
  ] : []

  # node pools
  ad_names = [
    for ad_name in data.oci_identity_availability_domains.ad_list.availability_domains :
    ad_name.name
  ]

  # network
  all_protocols = "all"
  icmp_protocol = 1
  tcp_protocol  = 6
  udp_protocol  = 17
  anywhere      = "0.0.0.0/0"

  # port numbers
  health_check_port = 10256
  node_port_min     = 30000
  node_port_max     = 32767

  // All services in Oracle Services Network
  osn = lookup(data.oci_core_services.all_oci_services.services[0], "cidr_block")


  # control plane
  cp_egress = [
    {
      description      = "Allow Kubernetes control plane to communicate with OKE",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow Kubernetes Control plane to communicate with worker nodes",
      destination      = data.oci_core_subnet.subnet["workers"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 10250,
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery to worker nodes",
      destination      = data.oci_core_subnet.subnet["workers"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
  ]

  cp_ingress = [
    {
      description = "Allow worker nodes to control plane API endpoint communication"
      protocol    = local.tcp_protocol,
      port        = 6443,
      source      = data.oci_core_subnet.subnet["workers"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow worker nodes to control plane communication"
      protocol    = local.tcp_protocol,
      port        = 12250,
      source      = data.oci_core_subnet.subnet["workers"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow ICMP traffic for path discovery from worker nodes"
      protocol    = local.icmp_protocol,
      port        = -1,
      source      = data.oci_core_subnet.subnet["workers"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
  ]

  # workers
  workers_egress = [
    {
      description      = "Allow ICMP traffic for path discovery",
      destination      = local.anywhere
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow worker nodes to communicate with OKE",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow worker nodes to control plane API endpoint communication",
      destination      = data.oci_core_subnet.subnet["cp"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 6443,
      stateless        = false
    },
    {
      description      = "Allow worker nodes to control plane communication",
      destination      = data.oci_core_subnet.subnet["cp"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = 12250,
      stateless        = false
    }
  ]

  workers_ingress = [
    {
      description = "Allow ingress for all traffic to allow pods to communicate between each other on different worker nodes on the worker subnet",
      protocol    = local.all_protocols,
      port        = -1,
      source      = data.oci_core_subnet.subnet["workers"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow control plane to communicate with worker nodes",
      protocol    = local.tcp_protocol,
      port        = 10250,
      source      = data.oci_core_subnet.subnet["cp"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow path discovery from worker nodes"
      protocol    = local.icmp_protocol,
      port        = -1,
      //this should be local.worker_subnet?
      // source      = local.anywhere,
      source      = data.oci_core_subnet.subnet["workers"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    }
  ]

  pods_egress = [
    {
      description      = "Allow pods to communicate with other pods.",
      destination      = data.oci_core_subnet.subnet["pods"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.all_protocols,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow pods to communicate with OCI Services",
      destination      = local.osn,
      destination_type = "SERVICE_CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = -1,
      stateless        = false
    },
  ]

  /*
  pods_ingress = [
    {
      description = "Allow Kubernetes Control Plane to communicate with pods.",
      protocol    = local.all_protocols,
      port        = -1,
      source      = data.oci_core_subnet.subnet["cp"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow worker nodes to access pods.",
      protocol    = local.all_protocols,
      port        = -1,
      source      = data.oci_core_subnet.subnet["workers"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
    {
      description = "Allow pods to communicate with each other.",
      protocol    = local.all_protocols,
      port        = -1,
      source      = data.oci_core_subnet.subnet["pods"].cidr_block,
      source_type = "CIDR_BLOCK",
      stateless   = false
    },
  ]
  */

  int_lb_egress = [
    {
      description      = "Allow stateful egress to workers. Required for NodePorts",
      destination      = data.oci_core_subnet.subnet["workers"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = "30000-32767",
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery to worker nodes",
      destination      = data.oci_core_subnet.subnet["workers"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
    {
      description      = "Allow stateful egress to workers. Required for load balancer http/tcp health checks",
      destination      = data.oci_core_subnet.subnet["workers"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = local.health_check_port,
      stateless        = false
    },
  ]

  # Create a Cartesian product of allowed cidrs and ports
  internal_lb_allowed_cidrs_and_ports = setproduct(var.internal_lb_allowed_cidrs, var.internal_lb_allowed_ports)
  public_lb_allowed_cidrs_and_ports   = setproduct(var.public_lb_allowed_cidrs, var.public_lb_allowed_ports)

  pub_lb_egress = [
    # {
    #   description      = "Allow stateful egress to internal load balancers subnet on port 80",
    #   destination      = local.int_lb_subnet,
    #   destination_type = "CIDR_BLOCK",
    #   protocol         = local.tcp_protocol,
    #   port             = 80
    #   stateless        = false
    # },
    # {
    #   description      = "Allow stateful egress to internal load balancers subnet on port 443",
    #   destination      = local.int_lb_subnet,
    #   destination_type = "CIDR_BLOCK",
    #   protocol         = local.tcp_protocol,
    #   port             = 443
    #   stateless        = false
    # },
    {
      description      = "Allow stateful egress to workers. Required for NodePorts",
      destination      = data.oci_core_subnet.subnet["workers"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.tcp_protocol,
      port             = "30000-32767",
      stateless        = false
    },
    {
      description      = "Allow ICMP traffic for path discovery to worker nodes",
      destination      = data.oci_core_subnet.subnet["workers"].cidr_block,
      destination_type = "CIDR_BLOCK",
      protocol         = local.icmp_protocol,
      port             = -1,
      stateless        = false
    },
  ]

  # 1. get a list of available images for this cluster
  # 2. filter by version
  # 3. if more than 1 image found for this version, pick the latest
  node_pool_image_ids = data.oci_containerengine_node_pool_option.node_pool_options.sources

  # kubernetes string version length
  k8s_version_length = length(var.cluster_kubernetes_version)
  k8s_version_only   = substr(var.cluster_kubernetes_version, 1, local.k8s_version_length)

}
