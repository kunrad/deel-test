output "cluster_id" {
  value = format("doctl kubernetes cluster kubeconfig save %s", digitalocean_kubernetes_cluster.my_cluster.id)
}

output "kubeconfig" {
  value = digitalocean_kubernetes_cluster.my_cluster.kube_config[0].raw_config
  sensitive = true
}