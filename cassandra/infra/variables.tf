variable "project_name" {
  type = string
}

variable "cluster_name" {
  default = "av-cassandra-k8s-cluster"
}

variable "region_name" {
  default = "europe-north1"
}

variable "location_name" {
  default = "europe-north1"
}

variable "count_vms" {
  default = "1"
}

variable "machine_type" {
  default = "e2-standard-2"
}


variable "k8s_master_version" {
  default = "1.16.15-gke.4901"
}

variable "gke_k8s_channel" {
  default = "STABLE"
}
