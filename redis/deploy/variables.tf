variable "data_namespace" {
  type        = string
  default     = "redis"
  description = "Неймспейс для развертывания кластера redis"
}

variable "monitoring_namespace" {
  type        = string
  default     = "monitoring"
  description = "Неймспейс для развертывания мониторинга для кластера redis"
}
