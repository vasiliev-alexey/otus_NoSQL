resource "helm_release" "redis" {

  name             = "redis"
  chart            = "redis"
  namespace        = var.data_namespace
  timeout          = 600
  repository       = "https://charts.bitnami.com/bitnami"
  create_namespace = true



  set {
    name  = "password"
    value = "redis"
  }

  set {
    name  = "metrics.enabled"
    value = true
  }
  set {
    name  = "sentinel.enabled"
    value = false
  }
  set {
    name  = "cluster.slaveCount"
    value = 3
  }


  set {
    name  = "metrics.serviceMonitor.namespace"
    value = var.monitoring_namespace
  }
  # fix Can't open the append-only file: Permission denied
  set {
    name  = "securityContext.fsGroup"
    value = 0
  }
  set {
    name  = "securityContext.enabled"
    value = true
  }

  set {
    name  = "securityContext.runAsUser"
    value = 0
  }
  set {
    name  = "containerSecurityContext.runAsUser"
    value = 0
  }

}

