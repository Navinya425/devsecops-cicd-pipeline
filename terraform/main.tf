terraform {
  required_version = ">= 1.0"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "= 2.23.0"
    }
  }
}

provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-devsecops"
}

# ============================================
# NAMESPACES — dev, staging, prod
# ============================================
resource "kubernetes_namespace" "dev" {
  metadata {
    name = "dev"
    labels = {
      app         = var.app_name
      environment = "dev"
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "staging" {
  metadata {
    name = "staging"
    labels = {
      app         = var.app_name
      environment = "staging"
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_namespace" "prod" {
  metadata {
    name = "prod"
    labels = {
      app         = var.app_name
      environment = "prod"
      managed-by  = "terraform"
    }
  }
}

# ============================================
# RESOURCE QUOTAS — limits per namespace
# ============================================
resource "kubernetes_resource_quota" "dev" {
  metadata {
    name      = "${var.app_name}-quota"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "500m"
      "requests.memory" = "512Mi"
      "limits.cpu"      = "1000m"
      "limits.memory"   = "1Gi"
      "pods"            = "5"
    }
  }
}

resource "kubernetes_resource_quota" "staging" {
  metadata {
    name      = "${var.app_name}-quota"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "500m"
      "requests.memory" = "512Mi"
      "limits.cpu"      = "1000m"
      "limits.memory"   = "1Gi"
      "pods"            = "5"
    }
  }
}

resource "kubernetes_resource_quota" "prod" {
  metadata {
    name      = "${var.app_name}-quota"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }
  spec {
    hard = {
      "requests.cpu"    = "1000m"
      "requests.memory" = "1Gi"
      "limits.cpu"      = "2000m"
      "limits.memory"   = "2Gi"
      "pods"            = "10"
    }
  }
}

# ============================================
# DEV DEPLOYMENT
# ============================================
resource "kubernetes_deployment" "dev" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.dev.metadata[0].name
    labels = {
      app         = var.app_name
      environment = "dev"
    }
  }
  spec {
    replicas = var.dev_replicas
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app         = var.app_name
          environment = "dev"
        }
      }
      spec {
        container {
          name  = var.app_name
          image = var.app_image
          image_pull_policy = "IfNotPresent"
          port {
            container_port = var.app_port
          }
          env {
            name  = "APP_ENV"
            value = "dev"
          }
          env {
            name  = "HOST"
            value = "0.0.0.0"
          }
          env {
            name = "APP_KEY"
            value_from {
              secret_key_ref {
                name = "${var.app_name}-secret"
                key  = "app-key"
              }
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# ============================================
# DEV SERVICE
# ============================================
resource "kubernetes_service" "dev" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.dev.metadata[0].name
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      port        = 80
      target_port = var.app_port
    }
    type = "NodePort"
  }
}

# ============================================
# STAGING DEPLOYMENT
# ============================================
resource "kubernetes_deployment" "staging" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.staging.metadata[0].name
    labels = {
      app         = var.app_name
      environment = "staging"
    }
  }
  spec {
    replicas = var.staging_replicas
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app         = var.app_name
          environment = "staging"
        }
      }
      spec {
        container {
          name  = var.app_name
          image = var.app_image
          image_pull_policy = "IfNotPresent"
          port {
            container_port = var.app_port
          }
          env {
            name  = "APP_ENV"
            value = "staging"
          }
          env {
            name  = "HOST"
            value = "0.0.0.0"
          }
          env {
            name = "APP_KEY"
            value_from {
              secret_key_ref {
                name = "${var.app_name}-secret"
                key  = "app-key"
              }
            }
          }
          resources {
            requests = {
              cpu    = "100m"
              memory = "128Mi"
            }
            limits = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# ============================================
# STAGING SERVICE
# ============================================
resource "kubernetes_service" "staging" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.staging.metadata[0].name
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      port        = 80
      target_port = var.app_port
    }
    type = "NodePort"
  }
}

# ============================================
# PROD DEPLOYMENT
# ============================================
resource "kubernetes_deployment" "prod" {
  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.prod.metadata[0].name
    labels = {
      app         = var.app_name
      environment = "prod"
    }
  }
  spec {
    replicas = var.prod_replicas
    selector {
      match_labels = {
        app = var.app_name
      }
    }
    template {
      metadata {
        labels = {
          app         = var.app_name
          environment = "prod"
        }
      }
      spec {
        container {
          name  = var.app_name
          image = var.app_image
          image_pull_policy = "IfNotPresent"
          port {
            container_port = var.app_port
          }
          env {
            name  = "APP_ENV"
            value = "production"
          }
          env {
            name  = "HOST"
            value = "0.0.0.0"
          }
          env {
            name = "APP_KEY"
            value_from {
              secret_key_ref {
                name = "${var.app_name}-secret"
                key  = "app-key"
              }
            }
          }
          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
          liveness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = var.app_port
            }
            initial_delay_seconds = 15
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# ============================================
# PROD SERVICE
# ============================================
resource "kubernetes_service" "prod" {
  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.prod.metadata[0].name
  }
  spec {
    selector = {
      app = var.app_name
    }
    port {
      port        = 80
      target_port = var.app_port
    }
    type = "NodePort"
  }
}