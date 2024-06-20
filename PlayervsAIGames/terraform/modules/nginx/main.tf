resource "kubernetes_deployment" "nginx" {
  metadata {
    name      = var.service_name
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = var.service_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.service_name
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"

          ports {
            container_port = 80
          }

          volume_mount {
            name       = "web-content"
            mount_path = "/usr/share/nginx/html"
          }
        }

        volume {
          name = "web-content"

          config_map {
            name = "web-content"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name      = var.service_name
    namespace = "default"
  }

  spec {
    selector = {
      app = var.service_name
    }

    type = "LoadBalancer"

    port {
      port        = 80
      target_port = 80
    }
  }
}

resource "kubernetes_config_map" "web_content" {
  metadata {
    name = "web-content"
  }

  data = {
    "index.html" = file("${path.module}/index.html")
  }
}

resource "aws_security_group" "nginx" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}
