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
  default = "europe-north1-b"
}

variable "count_vms" {
  default = "4"
}

variable "machine_type" {
  default = "e2-standard-2"
}
