# general oci parameters
variable "compartment_id" {}

variable "region" {}

# oke
variable "cluster_kubernetes_version" {}
variable "cluster_name" {}
variable "vcn_id" {}
variable "cni_type" {
  default = "npn" # "npn" or "flannel" but only npn will be supported in our case
}

variable "services_cidr" {
  default = "172.16.0.0/16"
}

variable "control_plane_allowed_cidrs" {
  type = list(string)
}

variable "freeform_tags" {
  type    = map(any)
  default = {}
}

variable "defined_tags" {
  type    = map(any)
  default = {}
}

variable "control_plane_type" {
  default = "private"
}

variable "subnets" {
  type = map(string)
}

# signed images
variable "use_signed_images" {
  type    = bool
  default = false
}

variable "image_signing_keys" {
  type    = list(string)
  default = []
}

# encryption
variable "use_cluster_encryption" {
  type = bool
}

variable "cluster_kms_key_id" {}

variable "create_policies" {
  type = bool
}

variable "use_node_pool_volume_encryption" {
  type = bool
}

variable "node_pool_volume_kms_key_id" {}

variable "is_kubernetes_dashboard_enabled" {
  default = false
}

# admission controller options
variable "admission_controller_options" {
  type = map(any)
}

variable "tenancy_id" {}

variable "node_pools" {
  type = any
}

variable "enable_pv_encryption_in_transit" {
  type = bool
}

variable "allow_worker_internet_access" {
  default = true
}

# internal load balancers
variable "internal_lb_allowed_cidrs" {
  type = list(any)
}

variable "internal_lb_allowed_ports" {
  type = list(any)
}

# public load balancers
variable "public_lb_allowed_cidrs" {
  type = list(any)
}

variable "public_lb_allowed_ports" {
  type = list(any)
}

variable "allow_pod_internet_access" {
  type    = bool
  default = true
}

variable "max_pods_per_node" {
  type = number
}

variable "cloudinit_nodepool_common" {
  type    = string
  default = ""
}

variable "cloudinit_nodepool" {
  type    = map(any)
  default = {}
}

variable "node_pool_timezone" {
  default = "Etc/UTC"
}

variable "node_pool_image_type" {
  default = "oke"
}

variable "node_pool_os_version" {}

variable "node_pool_image_id" {}

variable "ssh_public_key" {}

variable "ssh_public_key_path" {}
