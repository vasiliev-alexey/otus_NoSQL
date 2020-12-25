variable "project_name" {
  type = string
}

variable "cluster_name" {
  default = "av-redis-k8s-cluster"
}

variable "region_name" {
  default = "europe-north1"
}

variable "location_name" {
  default = "europe-north1-b"
}

variable "count_vms" {
  default = "3"
}

variable "machine_type" {
  default = "e2-standard-2"
}


variable "k8s_master_version" {
  default = "1.18.12-gke.1200"
}

variable "gke_k8s_channel" {
  default = "RAPID"
}
