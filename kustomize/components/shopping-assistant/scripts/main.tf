provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_project_service" "alloydb" {
  service = "alloydb.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  service = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "aiplatform" {
  service = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "generativelanguage" {
  service = "generativelanguage.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "alloydb_secret" {
  secret_id = var.alloydb_secret_name
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "alloydb_secret_version" {
  secret      = google_secret_manager_secret.alloydb_secret.id
  secret_data = var.pgpassword
}

resource "google_compute_global_address" "alloydb_service" {
  name          = var.alloydb_service_name
  address_type  = "INTERNAL"
  purpose       = "VPC_PEERING"
  prefix_length = 16
  network       = var.alloydb_network
}

resource "google_service_networking_connection" "alloydb_peering" {
  network                 = var.alloydb_network
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.alloydb_service.name]
  update_on_creation_fail = true
}

resource "google_alloydb_cluster" "alloydb_cluster" {
  cluster_id = var.alloydb_cluster_name
  location   = var.region
  network_config {
    network = var.alloydb_network
  }
  initial_user {
    password = var.pgpassword
  }
  automated_backup_policy {
    enabled = false
  }
}

resource "google_alloydb_instance" "alloydb_instance_primary" {
  instance_id = var.alloydb_instance_name
  cluster     = google_alloydb_cluster.alloydb_cluster.id
  machine_config {
   cpu_count   = 4 
  }
  network_config {
    enable_public_ip = true
  }
  database_flags = {
    "password.enforce_complexity" = "on"
  }
  instance_type = "PRIMARY"
}

resource "google_alloydb_instance" "alloydb_instance_replica" {
  instance_id = "${var.alloydb_instance_name}-replica"
  cluster     = google_alloydb_cluster.alloydb_cluster.id
  machine_config {
   cpu_count   = 4 
  }
  instance_type = "READ_POOL"
  read_pool_config {
    node_count = 2
  }
}

resource "google_service_account" "alloydb_user_gsa" {
  account_id   = var.alloydb_user_gsa_name
  display_name = var.alloydb_user_gsa_name
}

resource "google_project_iam_member" "alloydb_client_role" {
  project = var.project_id
  role    = "roles/alloydb.client"
  member  = "serviceAccount:${google_service_account.alloydb_user_gsa.email}"
}

resource "google_project_iam_member" "alloydb_database_user_role" {
  project = var.project_id
  role    = "roles/alloydb.databaseUser"
  member  = "serviceAccount:${google_service_account.alloydb_user_gsa.email}"
}

resource "google_project_iam_member" "secretmanager_secret_accessor_role" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.alloydb_user_gsa.email}"
}

resource "google_project_iam_member" "serviceusage_service_usage_consumer_role" {
  project = var.project_id
  role    = "roles/serviceusage.serviceUsageConsumer"
  member  = "serviceAccount:${google_service_account.alloydb_user_gsa.email}"
}

resource "google_project_iam_member" "aiplatform_user_role" {
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-alloydb.iam.gserviceaccount.com"
}

resource "google_service_account_iam_member" "cartservice_workload_identity_user" {
  service_account_id = google_service_account.alloydb_user_gsa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/cartservice]"
}

resource "google_service_account_iam_member" "shoppingassistantservice_workload_identity_user" {
  service_account_id = google_service_account.alloydb_user_gsa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/shoppingassistantservice]"
}

resource "google_service_account_iam_member" "productcatalogservice_workload_identity_user" {
  service_account_id = google_service_account.alloydb_user_gsa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[default/productcatalogservice]"
}

locals {
    alloydb_template = templatefile("${path.module}/alloydb.tftpl", {
        PROJECT_ID_VAL = var.project_id,
        REGION_VAL = var.region,
        ALLOYDB_PRIMARY_IP_VAL = google_alloydb_instance.alloydb_instance_primary.ip_address,
        ALLOYDB_USER_GSA_ID = google_service_account.alloydb_user_gsa.email,
        ALLOYDB_CLUSTER_NAME_VAL = var.alloydb_cluster_name,
        ALLOYDB_INSTANCE_NAME_VAL = var.alloydb_instance_name,
        ALLOYDB_CARTS_DATABASE_NAME_VAL = var.alloydb_carts_database_name,
        ALLOYDB_CARTS_TABLE_NAME_VAL = var.alloydb_carts_table_name,
        ALLOYDB_PRODUCTS_DATABASE_NAME_VAL = var.alloydb_products_database_name,
        ALLOYDB_PRODUCTS_TABLE_NAME_VAL = var.alloydb_products_table_name,        
        ALLOYDB_SECRET_NAME_VAL = var.alloydb_secret_name,        
    })
}

resource "local_file" "alloydb_template" {
    content  = local.alloydb_template
    filename = "${path.module}/alloydb.yaml"
}

locals {
    shoppingassistantservice_template = templatefile("${path.module}/shoppingassistantservice.tftpl", {
        PROJECT_ID_VAL = var.project_id,
        REGION_VAL = var.region,
        ALLOYDB_PRIMARY_IP_VAL = google_alloydb_instance.alloydb_instance_primary.ip_address,
        ALLOYDB_CLUSTER_NAME_VAL = var.alloydb_cluster_name,
        ALLOYDB_INSTANCE_NAME_VAL = var.alloydb_instance_name,
        ALLOYDB_DATABASE_NAME_VAL = var.alloydb_products_database_name,
        ALLOYDB_TABLE_NAME_VAL = var.alloydb_products_table_name,        
        ALLOYDB_SECRET_NAME_VAL = var.alloydb_secret_name,
        ALLOYDB_USER_GSA_ID = google_service_account.alloydb_user_gsa.email, 
    })
}

resource "local_file" "shoppingassistantservice_template" {
    content  = local.shoppingassistantservice_template
    filename = "${path.module}/shoppingassistantservice.yaml"
}


locals {
    step2_template = templatefile("${path.module}/step_2.tftpl", {
        REGION_VAL = var.region,
        ALLOYDB_PRIMARY_IP = google_alloydb_instance.alloydb_instance_primary.ip_address,
        ALLOYDB_CARTS_DATABASE_NAME = var.alloydb_carts_database_name,
        ALLOYDB_CARTS_TABLE_NAME = var.alloydb_carts_table_name,
        ALLOYDB_PRODUCTS_DATABASE_NAME = var.alloydb_products_database_name,
        ALLOYDB_PRODUCTS_TABLE_NAME = var.alloydb_products_table_name,         
    })
}

resource "google_compute_instance" "provisioner" {
  name         = "provisioner"
  machine_type = "e2-micro"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }
  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP
    }
  }
  connection {
      type    = "ssh"
      user    = var.ssh_user
      agent   = true
      host    = self.network_interface[0].access_config[0].nat_ip
  }
  provisioner "file" {
    source      = "${path.module}/generate_sql_from_products.py"
    destination = "/tmp/generate_sql_from_products.py"
  }
  provisioner "file" {
    source      = "../../../../src/productcatalogservice/products.json"
    destination = "/tmp/products.json"
  }
  provisioner "file" {
    content     = local.step2_template
    destination = "/tmp/2_create_populate_alloydb_tables.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y postgresql-client",
      "sudo chmod +x /tmp/2_create_populate_alloydb_tables.sh",
      "sudo chmod +x /tmp/generate_sql_from_products.py",
    ]
  }
}

output "provisioner_ip" {
value = google_compute_instance.provisioner.network_interface[0].access_config[0].nat_ip
}