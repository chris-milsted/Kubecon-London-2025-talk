resource "linode_lke_cluster" "lke_test_cluster" {
  label       = var.lke_cluster_label
  k8s_version = var.k8s_version
  region      = var.region

  pool {
    type  = var.lke_image_type
    count = 3
  }

}