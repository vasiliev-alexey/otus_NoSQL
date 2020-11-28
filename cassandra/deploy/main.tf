terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.3.0"

}

resource "helm_release" "cassandra" {

  name             = "cassandra-lab"
  chart            = "cassandra"
  namespace        = "cassandra"
  timeout          = 600
  repository       = "https://charts.bitnami.com/bitnami"
  create_namespace = true

  set {
    name  = "dbUser.user"
    value = "admin"
  }

  set {
    name  = "dbUser.password"
    value = "password"
  }

  set {
    name  = "cluster.seedCount"
    value = "3"
  }

  set {
    name  = "cluster.seedCount"
    value = "3"
  }

  set {
    name  = "replicaCount"
    value = "3"
  }




}
