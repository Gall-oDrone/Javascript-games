# Application Module for JavaScript 2D Game
# Following AWS Blueprints best practices

# Kubernetes Namespace
resource "kubernetes_namespace" "game" {
  metadata {
    name = var.namespace
    labels = {
      name = var.namespace
    }
  }
}

# Kubernetes Deployment
resource "kubernetes_deployment" "game" {
  depends_on = [kubernetes_namespace.game]

  metadata {
    name      = var.app_name
    namespace = kubernetes_namespace.game.metadata[0].name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          image = "${var.ecr_repository_url}:${var.image_tag}"
          name  = var.app_name

          port {
            container_port = var.container_port
          }

          resources {
            limits = {
              cpu    = var.container_cpu_limit
              memory = var.container_memory_limit
            }
            requests = {
              cpu    = var.container_cpu_request
              memory = var.container_memory_request
            }
          }

          liveness_probe {
            http_get {
              path = "/"
              port = var.container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
          }

          readiness_probe {
            http_get {
              path = "/"
              port = var.container_port
            }
            initial_delay_seconds = 5
            period_seconds        = 5
          }
        }
      }
    }
  }
}

# Kubernetes Service - Changed to ClusterIP for ALB
resource "kubernetes_service" "game" {
  depends_on = [kubernetes_namespace.game]

  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.game.metadata[0].name
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = var.service_port
      target_port = var.container_port
      protocol    = "TCP"
    }

    # Changed from LoadBalancer to ClusterIP for ALB ingress
    type = "ClusterIP"
  }
}

# Kubernetes Ingress - Fixed configuration
resource "kubernetes_ingress_v1" "game" {
  depends_on = [kubernetes_service.game]

  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.game.metadata[0].name
    annotations = merge(
      {
        # Required ALB annotations
        "kubernetes.io/ingress.class"               = "alb"
        "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
        "alb.ingress.kubernetes.io/target-type"     = "ip"
        
        # Health check configuration
        "alb.ingress.kubernetes.io/healthcheck-path"            = "/"
        "alb.ingress.kubernetes.io/healthcheck-interval-seconds" = "15"
        "alb.ingress.kubernetes.io/healthcheck-timeout-seconds"  = "5"
        "alb.ingress.kubernetes.io/healthy-threshold-count"      = "2"
        "alb.ingress.kubernetes.io/unhealthy-threshold-count"    = "2"
        "alb.ingress.kubernetes.io/success-codes"                = "200-399"
        
        # Group name for shared ALB
        "alb.ingress.kubernetes.io/group.name" = "${var.app_name}-${var.environment}"
        
        # Tags
        "alb.ingress.kubernetes.io/tags" = "Environment=${var.environment},Application=${var.app_name}"
      },
      # Only add HTTPS listeners if certificate is provided
      var.acm_certificate_arn != "" ? {
        "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}, {\"HTTPS\": 443}]"
        "alb.ingress.kubernetes.io/ssl-redirect"     = "443"
        "alb.ingress.kubernetes.io/certificate-arn"  = var.acm_certificate_arn
      } : {
        "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTP\": 80}]"
      }
    )
  }

  spec {
    ingress_class_name = "alb"
    
    rule {
      # Add host if domain is provided
      host = var.domain_name != "" ? var.domain_name : null
      
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.game.metadata[0].name
              port {
                number = var.service_port
              }
            }
          }
        }
      }
    }
    
    # Default backend for unmatched requests
    default_backend {
      service {
        name = kubernetes_service.game.metadata[0].name
        port {
          number = var.service_port
        }
      }
    }
  }
  
  # Wait for the service to be ready
  lifecycle {
    create_before_destroy = true
  }
}

# Horizontal Pod Autoscaler (if enabled)
resource "kubernetes_horizontal_pod_autoscaler_v2" "game" {
  count = var.enable_autoscaling ? 1 : 0
  
  depends_on = [kubernetes_deployment.game]

  metadata {
    name      = "${var.app_name}-hpa"
    namespace = kubernetes_namespace.game.metadata[0].name
  }

  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.game.metadata[0].name
    }

    min_replicas = var.hpa_min_replicas
    max_replicas = var.hpa_max_replicas

    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_cpu_target
        }
      }
    }

    metric {
      type = "Resource"
      resource {
        name = "memory"
        target {
          type                = "Utilization"
          average_utilization = var.hpa_memory_target
        }
      }
    }
  }
}