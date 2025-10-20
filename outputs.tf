output "kubeconfig" {
  value     = nonsensitive(talos_cluster_kubeconfig.talos.kubeconfig_raw)
}
