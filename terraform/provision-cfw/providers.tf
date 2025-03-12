data "linode_lke_cluster" "lke_cluster" {
  id = var.lke_cluster_id
}

locals {
  lke_kubeconfig_yaml = yamldecode(base64decode(data.linode_lke_cluster.lke_cluster.kubeconfig))
}

provider "helm" {
  kubernetes {
    host                   = local.lke_kubeconfig_yaml.clusters[0].cluster.server
    token                  = local.lke_kubeconfig_yaml.users[0].user.token
    cluster_ca_certificate = base64decode(local.lke_kubeconfig_yaml.clusters[0].cluster.certificate-authority-data)
  }
}

provider "linode" {

}