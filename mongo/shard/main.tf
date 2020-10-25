terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.00"
}


resource "helm_release" "mongodb" {
  name             = "mongodb"
  chart            = "mongodb-sharded"
  repository       = "https://charts.bitnami.com/bitnami"
  create_namespace = true
  timeout = 900
# Реплицируем управляющий контроллер на все 3 ноды
  set {
    name  = "mongos.replicas"
    value = 3
  }
# Реплицируем конфигурационный сервер на все 3 ноды
  set {
    name  = "configsvr.replicas"
    value = 3
  }
# Шардируем по 3
  set {
    name  = "shards"
    value = 3
  }
  
#  паролб для рута
  set {
    name  = "mongodbRootPassword"
    value = "mongopass"
  }
# включаем сбор метрик для prometheus  
  set {
    name  = "metrics.enabled"
    value = true
  }

    set {
    name  = "metrics.serviceMonitor.enable"
    value = true
  }
      set {
    name  = "metrics.kafka.enabled"
    value = true
  }
  

  
  
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  chart      = "stable/prometheus"
  namespace = "monitoring"
  create_namespace = true


  values = [<<EOF

serverFiles:
 prometheus.yml:
    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
            - localhost:9090
      - job_name: 'mongodb'
        static_configs:
          - targets:
            - 'mongodb-mongodb-sharded.default.svc.cluster.local:9216'
EOF
  ]

 

}


resource "helm_release" "grafana" {
  name             = "grafana"
  chart            = "stable/grafana"
  namespace        = "monitoring"
  create_namespace = true



}