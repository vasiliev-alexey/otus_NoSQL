terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 2.0.0"
  kubernetes {
    config_path = "~/.kube/config"
  }
}



provider "kubernetes-alpha" {
  config_path = "~/.kube/config"
  version     = "~> 0.2"
}

