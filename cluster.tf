
# 30s delay to allow policies to take effect globally
resource "time_sleep" "wait_30_seconds" {
  depends_on = [oci_identity_policy.oke_kms]

  create_duration = "30s"
}

resource "oci_containerengine_cluster" "oke_cluster" {
  #Required
  compartment_id     = var.compartment_id
  kubernetes_version = var.cluster_kubernetes_version
  name               = var.cluster_name
  vcn_id             = var.vcn_id
  kms_key_id         = var.use_cluster_encryption == true ? var.cluster_kms_key_id : null

  #Optional
  cluster_pod_network_options {
    #Required
    cni_type = var.cni_type == "flannel" ? "FLANNEL_OVERLAY" : "OCI_VCN_IP_NATIVE"
  }

  //defined_tags  = var.defined_tags["cp"]
  freeform_tags = var.freeform_tags["cp"]

  endpoint_config {

    #Optional
    is_public_ip_enabled = var.control_plane_type == "public" ? true : false
    nsg_ids              = [oci_core_network_security_group.cp.id]
    subnet_id            = var.subnets["cp"]
  }

  dynamic "image_policy_config" {
    for_each = var.use_signed_images == true ? [1] : []

    content {
      is_policy_enabled = true

      dynamic "key_details" {
        iterator = signing_keys_iterator
        for_each = var.image_signing_keys

        content {
          kms_key_id = signing_keys_iterator.value
        }
      }
    }
  }

  options {
    #Optional
    add_ons {

      #Optional
      is_kubernetes_dashboard_enabled = var.is_kubernetes_dashboard_enabled
      is_tiller_enabled               = false
    }
    admission_controller_options {

      #Optional
      is_pod_security_policy_enabled = var.admission_controller_options.PodSecurityPolicy
    }
    kubernetes_network_config {

      #Optional
      services_cidr = var.services_cidr
    }
    persistent_volume_config {

      #Optional
      //defined_tags  = var.defined_tags["pvc"]
      freeform_tags = var.freeform_tags["pvc"]
    }
    service_lb_config {

      #Optional
      //defined_tags  = var.defined_tags["service_lb"]
      freeform_tags = var.freeform_tags["service_lb"]
    }
    // define lb variable separately if that needs to be multiple subnets
    //service_lb_subnet_ids = [ var.cluster_subnets.lb ]
    service_lb_subnet_ids = [var.subnets["lb"]]
  }
}
