resource "oci_identity_dynamic_group" "oke_kms_cluster" {
  //provider       = oci.home
  compartment_id = var.tenancy_id
  description    = "dynamic group to allow cluster to use KMS to encrypt etcd"
  matching_rule  = local.dynamic_group_rule_all_clusters
  name           = "${var.cluster_name}-group"
  count          = var.use_cluster_encryption == true && var.create_policies == true ? 1 : 0

  lifecycle {
    ignore_changes = [matching_rule]
  }
}

resource "oci_identity_policy" "oke_kms" {
  compartment_id = var.compartment_id
  description    = "policy to allow dynamic group ${var.cluster_name}-group to use KMS to encrypt etcd"
  depends_on     = [oci_identity_dynamic_group.oke_kms_cluster]
  name           = "${var.cluster_name}-oke-kms"

  statements = [local.cluster_kms_policy_statement]

  count = var.use_cluster_encryption == true && var.create_policies == true ? 1 : 0

}

resource "oci_identity_policy" "oke_volume_kms" {
  compartment_id = var.compartment_id
  description    = "Policies for block volumes to access kms key"
  name           = "${var.cluster_name}-oke-volume-kms"
  statements     = local.oke_volume_kms_policy_statements

  count = var.use_node_pool_volume_encryption == true && var.create_policies == true ? 1 : 0

}
