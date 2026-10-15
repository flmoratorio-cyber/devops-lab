terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

# Local Docker daemon on the control node (default socket: unix:///var/run/docker.sock)
provider "docker" {}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_container" "nginx" {
  name  = var.container_name
  image = docker_image.nginx.image_id
  env   = ["ENVIRONMENT=training"]

  ports {
    internal = 80
    external = var.external_port
  }
}
