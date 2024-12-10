variable "project_id" {
  description = "The ID of the project in which to create resources."
}

variable "project_number" {
  description = "The project number."
}

variable "pgpassword" {
  description = "The password for the AlloyDB instance."
}

variable "region" {
  description = "The region in which to create resources."
  default     = "us-central1"
}

variable "zone" {
  description = "The region in which to create resources."
  default     = "us-central1-a"
}

variable "ssh_user" {
  description = "User to SSH into the VM."
}

variable "alloydb_network" {
  description = "The network for AlloyDB."
  default     = "default"
}

variable "alloydb_service_name" {
  description = "The service name for AlloyDB."
  default     = "onlineboutique-network-range"
}

variable "alloydb_cluster_name" {
  description = "The cluster name for AlloyDB."
  default     = "onlineboutique-cluster"
}

variable "alloydb_instance_name" {
  description = "The instance name for AlloyDB."
  default     = "onlineboutique-instance"
}

variable "alloydb_carts_database_name" {
  description = "The database name for carts."
  default     = "carts"
}

variable "alloydb_carts_table_name" {
  description = "The table name for cart items."
  default     = "cart_items"
}

variable "alloydb_products_database_name" {
  description = "The database name for products."
  default     = "products"
}

variable "alloydb_products_table_name" {
  description = "The table name for catalog items."
  default     = "catalog_items"
}

variable "alloydb_user_gsa_name" {
  description = "The service account name for AlloyDB user."
  default     = "alloydb-user-sa"
}

variable "alloydb_secret_name" {
  description = "The secret name for AlloyDB."
  default     = "alloydb-secret"
}