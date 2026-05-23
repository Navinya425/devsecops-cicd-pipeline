variable "app_name" {
  description = "Application name"
  type        = string
  default     = "devsecops-app"
}

variable "namespaces" {
  description = "Kubernetes namespaces for each environment"
  type        = list(string)
  default     = ["dev", "staging", "prod"]
}

variable "app_image" {
  description = "Docker image for the application"
  type        = string
  default     = "devsecops-app:latest"
}

variable "app_port" {
  description = "Port the application listens on"
  type        = number
  default     = 5000
}

variable "dev_replicas" {
  description = "Number of replicas in dev"
  type        = number
  default     = 1
}

variable "staging_replicas" {
  description = "Number of replicas in staging"
  type        = number
  default     = 1
}

variable "prod_replicas" {
  description = "Number of replicas in prod"
  type        = number
  default     = 2
}