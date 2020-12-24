resource "helm_release" "cassandra" {

  name             = "cassandra-lab"
  chart            = "cassandra"
  namespace        = "cassandra"
  timeout          = 600
  repository       = "https://charts.bitnami.com/bitnami"
  create_namespace = true

depends_on = [kubernetes_manifest.crd_servicemonitors_monitoring_coreos_com]

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
    name  = "podLabels.app"
    value = "cassandra"
  }





  set {
    name  = "cluster.seedCount"
    value = "3"
  }

  set {
    name  = "replicaCount"
    value = "3"
  }

  set {
    name  = "metrics.enabled"
    value = var.monitoring_enable
  }
  set {
    name  = "metrics.serviceMonitor.enabled"
    value = var.monitoring_enable
  }

  set {
    name  = "metrics.serviceMonitor.namespace"
    value = "monitoring"
  }

}
