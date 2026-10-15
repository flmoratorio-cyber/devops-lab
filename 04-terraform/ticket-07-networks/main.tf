terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

provider "docker" {}

resource "docker_network" "internal" {
  name   = "internal_net"
  driver = "bridge"

  ipam_config {
    subnet = "10.10.0.0/24"
  }
}

resource "docker_image" "nginx" {
  name = "nginx:alpine"
}

resource "docker_image" "alpine" {
  name = "alpine:latest"
}

# No published ports: reachable only from inside the private network
resource "docker_container" "web_server" {
  name  = "web_server"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.internal.name
  }
}

resource "docker_container" "test_client" {
  name    = "test_client"
  image   = docker_image.alpine.image_id
  command = ["sleep", "infinity"] # keep the container alive for exec tests

  networks_advanced {
    name = docker_network.internal.name
  }
}
