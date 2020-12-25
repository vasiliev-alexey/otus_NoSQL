resource "helm_release" "nginx_ingress" {
  name             = "nginx-ingress"
  chart            = "nginx-ingress"
  timeout          = 600
  repository       = "https://helm.nginx.com/stable"
  create_namespace = true
  namespace        = var.ingress_namespace


  set {
    name  = "controller.service.loadBalancerIP"
    value = google_compute_address.ip_address.address
  }



}