# Application Module for JavaScript 2D Game
# Following AWS Blueprints best practices

# ECR Repository for the game
resource "aws_ecr_repository" "game" {
  name                 = "${var.project_name}-game"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = var.tags
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "game" {
  repository = aws_ecr_repository.game.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 5 images"
        selection = {
          tagStatus     = "untagged"
          countType     = "imageCountMoreThan"
          countNumber   = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

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
          image = "${aws_ecr_repository.game.repository_url}:${var.image_tag}"
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

# Kubernetes Service
resource "kubernetes_service" "game" {
  depends_on = [kubernetes_namespace.game]

  metadata {
    name      = "${var.app_name}-service"
    namespace = kubernetes_namespace.game.metadata[0].name
    annotations = {
      "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
    }
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = var.service_port
      target_port = var.container_port
    }

    type = "LoadBalancer"
  }
}

# Kubernetes Ingress
resource "kubernetes_ingress_v1" "game" {
  depends_on = [kubernetes_service.game]

  metadata {
    name      = "${var.app_name}-ingress"
    namespace = kubernetes_namespace.game.metadata[0].name
    annotations = {
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/"
    }
  }

  spec {
    ingress_class_name = "alb"
    
    rule {
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
  }
}
