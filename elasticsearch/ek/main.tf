terraform {
  required_version = ">= 0.12.26"
}

provider "helm" {
  version = "~> 1.00"

}

provider "google" {
  version = "~> 3.15.0"
  project = var.project_name
  region  = var.region_name
}


data "google_compute_address" "ip_address" {
  name = "ip-adress-for-nginx-ingress"
}


resource "helm_release" "nginx" {
  name             = "nginx"
  chart            = "stable/nginx-ingress"
  namespace        = "nginx-ingress"
  create_namespace = true

  # Должно быть развернуто три реплики controller
  values = [<<EOF
controller:
  replicaCount: 1
  config:
    log-format-escape-json: "true"
    log-format-upstream: '{"remote_addr": "$remote_addr", 
        "x-forward-for": "$proxy_add_x_forwarded_for", 
        "request_id": "$req_id", 
        "remote_user": "$remote_user", 
        "bytes_sent": "$bytes_sent", 
        "request_time": "$request_time", 
        "status": "$status",
        "vhost": "$host", 
        "request_proto": "$server_protocol", 
        "path": "$uri",
        "request_query": "$args", 
        "request_length": "$request_length",
        "duration": "$request_time", 
        "method": "$request_method", 
        "http_referrer": "$http_referer", 
        "http_user_agent": "$http_user_agent"}'
  tolerations:
    - key: node-role
      operator: Equal
      value: infra
      effect: NoSchedule
  affinity:
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - nginx-ingress
          topologyKey: kubernetes.io/hostname
  nodeSelector: 
    cloud.google.com/gke-nodepool: infra-pool
  metrics:
    enabled: true
    serviceMonitor:
      enabled: false
      namespace: observability
EOF
  ]

  set {
    name  = "controller.service.loadBalancerIP"
    value = data.google_compute_address.ip_address.address
  }


}




resource "helm_release" "elasticsearch" {
  name             = "elasticsearch"
  chart            = "elasticsearch"
  namespace        = var.efk_namespace
  repository       = "https://helm.elastic.co"
  create_namespace = true
  timeout = 600    
 
  values = [<<EOF

ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  path: /
  hosts:
  - elasticsearch.${data.google_compute_address.ip_address.address}.xip.io


nodeSelector:
  cloud.google.com/gke-nodepool: infra-pool
tolerations:
- key: node-role
  operator: Equal
  value: infra
  effect: NoSchedule

EOF
  ]


}


resource "helm_release" "kibana" {
  name             = "kibana"
  chart            = "kibana"
  namespace        = var.efk_namespace
  repository       = "https://helm.elastic.co"
  create_namespace = true
  count            = 1


  values = [<<EOF
ingress:
  enabled: true
  annotations:
    kubernetes.io/ingress.class: nginx
  path: /
  hosts:
  - kibana.${data.google_compute_address.ip_address.address}.xip.io

EOF
  ]

}
