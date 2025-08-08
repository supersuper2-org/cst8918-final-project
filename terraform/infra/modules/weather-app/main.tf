# Azure Container Registry
resource "azurerm_container_registry" "main" {
  name                = var.acr_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = "Basic"
  admin_enabled       = true
  tags                = var.tags
}

# Azure Cache for Redis
resource "azurerm_redis_cache" "main" {
  name                = "${var.environment}-redis-${random_string.suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  capacity            = var.redis_capacity
  family              = "C"
  sku_name            = var.redis_sku
  non_ssl_port_enabled = false
  tags                = var.tags
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Kubernetes Provider Configuration
provider "kubernetes" {
  host                   = var.kubernetes_host
  client_certificate     = var.kubernetes_client_certificate
  client_key             = var.kubernetes_client_key
  cluster_ca_certificate = var.kubernetes_cluster_ca_certificate
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
    redis-host = azurerm_redis_cache.main.hostname
    redis-port = azurerm_redis_cache.main.ssl_port
    redis-key  = azurerm_redis_cache.main.primary_access_key
  }
}

# Kubernetes ConfigMap for Application Configuration
resource "kubernetes_config_map" "weather_app_config" {
  metadata {
    name      = "weather-app-config"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
  }

  data = {
    REDIS_HOST = azurerm_redis_cache.main.hostname
    REDIS_PORT = azurerm_redis_cache.main.ssl_port
    REDIS_KEY  = azurerm_redis_cache.main.primary_access_key
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "weather_app" {
  metadata {
    name      = "weather-app"
    namespace = kubernetes_namespace.weather_app.metadata[0].name
  }

  spec {
    replicas = var.app_replicas

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
          image = "${azurerm_container_registry.main.login_server}/weather-app:latest"
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