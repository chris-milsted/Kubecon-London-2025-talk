output lke_cloud_firewall_id {
  # when I was testing, even though there is an implicit dependency for
  # the data resource block that this output block references, it tries to resolve
  # a value before the controller is deployed.  This try statement is
  # a workaround for the observed issue after exhaustively troubleshooting.
  # I did notice that if you use data.linode_firewalls.lke_cloud_firewall.id 
  # instead of drilling into the structure this output will wait on the
  # dependency, but as soon as you drill into the firewalls array it fails
  value = try(data.linode_firewalls.lke_cloud_firewall.firewalls.0.id, null)
}