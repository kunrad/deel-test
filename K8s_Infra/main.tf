terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0" # Use the latest 2.x version
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1.0"
    }
  }
}

provider "digitalocean" {

  token = var.digitalocean_token
}


data "digitalocean_kubernetes_versions" "current" {}

resource "digitalocean_kubernetes_cluster" "my_cluster" {
  name    = "my-k8s-cluster"
  region  = "sfo3" # Replace with your preferred region
  version = data.digitalocean_kubernetes_versions.current.latest_version

  node_pool {
    name       = "default-pool"
    size       = "s-2vcpu-2gb" # Replace with your preferred node size
    node_count = 1             # The name of Nodes. 
  }
}

resource "digitalocean_kubernetes_node_pool" "additional_node" {
  cluster_id = digitalocean_kubernetes_cluster.my_cluster.id
  name       = "additional-node-pool"
  size       = "s-2vcpu-2gb" # Replace with your preferred node size
  node_count = 1

  tags = ["k8s", "additional-node"]
}