output "kibana-url" {
  value = "http://kibana.${data.google_compute_address.ip_address.address}.xip.io"
}
output "elasticsearch-url" {
  value = "http://elasticsearch.${data.google_compute_address.ip_address.address}.xip.io"
}