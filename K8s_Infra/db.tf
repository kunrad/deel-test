locals {
  database_cluster_name = "reverseapp-db"
}
resource "digitalocean_database_db" "db" {
  cluster_id = digitalocean_database_cluster.db_cluster.id
  name       = "reverseip"
}
resource "digitalocean_database_cluster" "db_cluster" {
  name                 = local.database_cluster_name
  engine               = "pg"
  version              = "17"
  size                 = "db-s-1vcpu-1gb" 
  region               = "sfo3"
  node_count           = 1
#   private_network_uuid = "default-sfo3"

  tags = ["reverseip"]
}

resource "digitalocean_database_user" "db_user" {
  cluster_id = digitalocean_database_cluster.db_cluster.id
  name       = "user"
#   password   = random_string.db_password.result
}