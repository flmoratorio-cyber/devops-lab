terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

provider "docker" {}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

# Lifecycle of the data is decoupled from the lifecycle of the container
resource "docker_volume" "web_data" {
  name = "web_data"
}

resource "docker_container" "nginx" {
  name  = var.container_name
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = var.external_port
  }

  # Option A: Docker-managed volume
  volumes {
    volume_name    = docker_volume.web_data.name
    container_path = "/usr/share/nginx/html" # absolute path (leading slash)
  }

  # Option B: bind mount instead of the volume above
  # volumes {
  #   host_path      = "${path.cwd}/site"
  #   container_path = "/usr/share/nginx/html"
  #   read_only      = false
  # }
}
