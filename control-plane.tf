resource "libvirt_volume" "controlplane" {
  count = 3

  name = "controlplane${count.index}.qcow2"
  base_volume_name = "metal-amd64.qcow2"
  size = 40*1024*1024*1024
  pool = "pool"
}

resource "libvirt_domain" "controlplane" {
  count = 3

  name = "cp${count.index}"
  memory = "4096"
  vcpu = 4

  network_interface {
    network_id     = libvirt_network.kube_network.id
    hostname       = "controlplane${count.index}"
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.controlplane[count.index].id
    scsi      = true
  }

  cpu {
    mode = "host-passthrough"
  }
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  count = 3

  cluster_name     = "example-cluster"
  machine_type     = "controlplane"
  cluster_endpoint = "https://${libvirt_domain.controlplane[0].network_interface.0.addresses.0}:6443"
  machine_secrets  = talos_machine_secrets.this.machine_secrets

  config_patches = [
    yamlencode({
      cluster = {
        network = {
          cni = {
            name = "none"
          }
        }
        proxy = {
          disabled = true
        }
      }
    }),
    yamlencode({
      machine = {
        network = {
          hostname = "cp${count.index}"
        }
      }
    }),
  ]
}

resource "talos_machine_configuration_apply" "controlplane" {
  count = 3

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.controlplane[count.index].machine_configuration
  node                        = libvirt_domain.controlplane[count.index].network_interface.0.addresses.0
}

resource "talos_machine_bootstrap" "controlplane" {
  count = 3

  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]
  node                 = libvirt_domain.controlplane[count.index].network_interface.0.addresses.0
  client_configuration = talos_machine_secrets.this.client_configuration
}

resource "talos_cluster_kubeconfig" "talos" {
  client_configuration = talos_machine_secrets.this.client_configuration
  endpoint             = libvirt_domain.controlplane[0].network_interface.0.addresses.0
  node                 = libvirt_domain.controlplane[0].network_interface.0.addresses.0
  depends_on = [
    talos_machine_bootstrap.controlplane,
  ]
}
