terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

# Talk to the Docker daemon on wk1 through an SSH tunnel (no TCP socket exposed)
provider "docker" {
  host     = var.docker_host
  ssh_opts = ["-o", "StrictHostKeyChecking=accept-new", "-i", pathexpand("~/.ssh/lab_master")]
}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_container" "nginx" {
  name  = "nginx-remote"
  image = docker_image.nginx.image_id

  ports {
    internal = 80
    external = 8085
  }
}
