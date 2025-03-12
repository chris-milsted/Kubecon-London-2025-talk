resource "helm_release" "cloud_firewall_crd" {
  name       = "cloud-firewall-crd"
  repository = "https://linode.github.io/cloud-firewall-controller"
  chart      = "cloud-firewall-crd"
}

resource "helm_release" "cloud_firewall_ctrl" {
  name       = "cloud-firewall-ctrl"
  repository = "https://linode.github.io/cloud-firewall-controller"
  chart      = "cloud-firewall-controller"
  depends_on = [ helm_release.cloud_firewall_crd ]
}

# I noticed during testing that sometimes the cloud firewall takes
# several seconds to provision after the controller is deployed so
# this added sleep is here to ensure the cloud resource is availble
# to be consumed by the data resource
resource "time_sleep" "allow_firewall_creation" {
  create_duration = "30s"
  triggers = {
    controller_release_version = helm_release.cloud_firewall_ctrl.version
    lke_cloud_firewall_label = "lke-${var.lke_cluster_id}"
  }
}

# The values resource below is meant to enable a dependency between
# the controller being deployed and the firewall existing using
# the sleep task above
data "linode_firewalls" "lke_cloud_firewall" {
  filter {
    name = "label"
    values = [ time_sleep.allow_firewall_creation.triggers["lke_cloud_firewall_label"] ]
  }
}
