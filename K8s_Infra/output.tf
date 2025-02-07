output "kubectl_save" {
  value = format("doctl kubernetes cluster kubeconfig save %s", digitalocean_kubernetes_cluster.my_cluster.id)
}

output "kubeconfig" {
  value     = digitalocean_kubernetes_cluster.my_cluster.kube_config[0].raw_config
  sensitive = true
}

output "cluster_id" {
  value = digitalocean_kubernetes_cluster.cluster.id
  description = "Extracted DigitalOcean Kubernetes Cluster ID"
}