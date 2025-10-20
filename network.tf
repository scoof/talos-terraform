resource "libvirt_network" "kube_network" {
  name = "k8snet"
  mode = "nat"
  addresses = ["10.17.3.0/24"]
  dns {
    enabled = true
  }

  dhcp {
    enabled = true
  }
}
