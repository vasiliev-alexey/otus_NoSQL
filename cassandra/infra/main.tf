terraform {
  required_version = ">= 0.12.26"
 
}

provider "google" {
  version     = "~> 3.15.0"
  project     = var.project_name
  region      = var.region_name
}

resource "google_container_cluster" "av-k8s-cluster" {
  name     = var.cluster_name
  location = var.location_name
  provider                 = google-beta
  remove_default_node_pool = true
  initial_node_count       = 1
  project     = var.project_name

  addons_config {
    istio_config {
      disabled = false
      auth     = "AUTH_NONE"
    }
  }
  master_auth {
    username = ""
    password = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --zone ${var.location_name} --project ${var.project_name}"
  }




}

resource "google_container_node_pool" "av-k8s-nodes" {
  name       = "av-k8s-node-pool"
  location   = var.location_name
  cluster    = google_container_cluster.av-k8s-cluster.name
  node_count = var.count_vms

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    disk_size_gb = 30

    metadata = {
      disable-legacy-endpoints = "true"
    }








    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
