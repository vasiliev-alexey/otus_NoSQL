resource "helm_release" "prometheus" {

  name             = "prometheus"
  chart            = "prometheus"
  namespace        = var.monitoring_namespace
  timeout          = 600
  repository       = "https://prometheus-community.github.io/helm-charts"
  create_namespace = true
 count = var.monitoring_enable? 1: 0

  #  set {
  #    name  = "server.ingress.hosts"
  #    value = "{prometheus.${var.domain_name}}"
  #  }

  set {
    name  = "server.ingress.hosts"
    value = "{prometheus.${local.service_name}}"
  }



  set {
    name  = "alertmanager.enabled"
    value = "false"
  }
  set {
    name  = "exporters.enabled"
    value = "false"
  }

  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "pushgateway.enabled"
    value = "false"
  }

  set {
    name  = "nodeExporter.enabled"
    value = "false"
  }


  set {
    name  = "server.ingress.annotations.kubernetes\\.io/ingress\\.class"
    value = "nginx"
  }
  set {
    name = "extraScrapeConfigs"
    # value = "nginx"





    value = <<EOF

- job_name: 'cassandra'
  metrics_path: '/metrics'
  kubernetes_sd_configs:
    - role: pod
      namespaces:
        names:
          - ${var.data_namespace}
  relabel_configs:
    - source_labels: [__meta_kubernetes_pod_container_port_number]
      action: keep
      regex: 8080
    - action: labelmap
      regex: __meta_kubernetes_pod_label_(.+)
    - source_labels: [__meta_kubernetes_pod_name]
      action: replace
      target_label: kubernetes_pod_name
EOF

  }
}

