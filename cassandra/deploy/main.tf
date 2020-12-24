terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.3.0"

}


provider "google" {
  version     = "~> 3.15.0"
  project     = var.project_name
#  region      = var.region_name

}


provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
  version     = "~> 0.2"
}


resource "google_compute_address" "ip_address" {
  name = "ip-adress-for-nginx-ingress"
    region        = var.region_name
}


locals {
  service_name     =  "${google_compute_address.ip_address.address}.xip.io"

}



