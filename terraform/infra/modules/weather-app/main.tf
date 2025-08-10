# Kubernetes config
provider "kubernetes" {
  host                   = var.k8s_host
  client_certificate     = var.k8s_client_certificate
  client_key             = var.k8s_client_key
  cluster_ca_certificate = var.k8s_cluster_ca_certificate
  config_path            = null
  config_context         = null
}

# Kubernetes Namespace
resource "kubernetes_namespace" "weather_app" {
  metadata {
    name = "weather-app"
  }
}

# Kubernetes Secret for Redis Connection
resource "kubernetes_secret" "redis_secret" {
  metadata {
    name      = "redis-secret"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
  }

  data = {
    redis-host = var.redis_hostname
    redis-port = var.redis_ssl_port
    redis-key  = var.redis_primary_key
  }
}

# Kubernetes ConfigMap for Application Configuration
resource "kubernetes_config_map" "weather_app_config" {
  metadata {
    name      = "weather-app-config"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
  }

  data = {
    REDIS_HOST = var.redis_hostname
    REDIS_PORT = var.redis_ssl_port
    REDIS_KEY  = var.redis_primary_key
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "weather_app" {
  metadata {
    name      = "weather-app"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "weather-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "weather-app"
        }
      }

      spec {
        container {
          image = "${var.acr_login_server}/weather-app:latest"
          name  = "weather-app"

          port {
            container_port = 3000
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.weather_app_config.metadata[0].name
            }
          }

          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }

          liveness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 3000
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Kubernetes Service
resource "kubernetes_service" "weather_app" {
  metadata {
    name      = "weather-app-service"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
  }

  spec {
    selector = {
      app = "weather-app"
    }

    port {
      port        = 80
      target_port = 3000
    }

    type = "LoadBalancer"
  }
} 