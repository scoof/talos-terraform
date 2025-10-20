resource "libvirt_pool" "pool" {
  name = "pool"
  type = "dir"
  target {
    path = "/home/ap/talos-tf/pool"
  }
}
