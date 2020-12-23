variable "project_name" {
  type = string
  description = "Код проекта в GCP"
}


variable "monitoring_namespace" {
  type        = string
  default     = "monitoring"
  description = "Неймспейс для развертывания инфраструктуры мониторинга и логирования"
}


variable "monitoring_enable" {
  type        = bool
  default     = false

}

variable "data_namespace" {
  type        = string
  default     = "cassandra"
  description = "Неймспейс для развертывания БД"
}

variable "ingress_namespace" {
  type        = string
  default     = "ingress"
  description = "Неймспейс для развертывания Ingress Nginx"
}

variable "region_name" {
  default = "europe-north1"
}

