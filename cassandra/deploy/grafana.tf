resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "grafana"
  timeout          = 600
  repository       = "https://grafana.github.io/helm-charts"
  create_namespace = true
count = var.monitoring_enable? 1: 0
  namespace        = var.monitoring_namespace


  set {
    name  = "ingress.hosts"
    value = "{grafana.${local.service_name}}"
  }

  set {
    name  = "adminPassword"
    value = "admin"
  }

  set {
    name  = "ingress.enabled"
    value = true
  }

  set {
    name  = "service.type"
    value = "NodePort"
  }
  set {
    name  = "service.port"
    value = "3000"
  }

  set {
    name  = "ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"

  }





  values = [<<EOF
ingress:
    enabled: true
#    annotations: {
#      kubernetes.io/ingress.class: nginx
#    }
    path: /


datasources: 
  datasources.yaml:
    apiVersion: 1
    datasources:
    - name: Prometheus
      type: prometheus
      url: http://prometheus-server
      access: proxy
      isDefault: true



dashboardProviders: 
  dashboardproviders.yaml:
    apiVersion: 1
    providers:
    - name: 'prometheus'
      orgId: 1
      folder: 'Cassandra'
      type: file
      disableDeletion: true
      editable: true
      options:
        path: /var/lib/grafana/dashboards/prometheus


dashboards: 
  default:
  prometheus:
    Cassandra:
      gnetId: 6258
      datasource: Prometheus

EOF
  ]


}
