terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 4.2.0"
    }
  }
}

# One provider configuration (alias) per worker
provider "docker" {
  alias = "wk1"
  host  = var.host_wk1
}
provider "docker" {
  alias = "wk2"
  host  = var.host_wk2
}
provider "docker" {
  alias = "wk3"
  host  = var.host_wk3
}
provider "docker" {
  alias = "wk4"
  host  = var.host_wk4
}

# ---- wk1 ----
resource "docker_image" "nginx_wk1" {
  provider     = docker.wk1
  name         = "nginx:latest"
  keep_locally = false
}
resource "docker_container" "nginx_wk1" {
  provider = docker.wk1
  name     = "nginx-wk1"
  image    = docker_image.nginx_wk1.image_id
  env      = ["ENVIRONMENT=training"]
  ports {
    internal = 80
    external = var.port_wk1
  }
}

# ---- wk2 ----
resource "docker_image" "nginx_wk2" {
  provider     = docker.wk2
  name         = "nginx:latest"
  keep_locally = false
}
resource "docker_container" "nginx_wk2" {
  provider = docker.wk2
  name     = "nginx-wk2"
  image    = docker_image.nginx_wk2.image_id
  ports {
    internal = 80
    external = var.port_wk2
  }
}

# ---- wk3 ----
resource "docker_image" "nginx_wk3" {
  provider     = docker.wk3
  name         = "nginx:latest"
  keep_locally = false
}
resource "docker_container" "nginx_wk3" {
  provider = docker.wk3
  name     = "nginx-wk3"
  image    = docker_image.nginx_wk3.image_id
  ports {
    internal = 80
    external = var.port_wk3
  }
}

# ---- wk4 ----
resource "docker_image" "nginx_wk4" {
  provider     = docker.wk4
  name         = "nginx:latest"
  keep_locally = false
}
resource "docker_container" "nginx_wk4" {
  provider = docker.wk4
  name     = "nginx-wk4"
  image    = docker_image.nginx_wk4.image_id
  ports {
    internal = 80
    external = var.port_wk4
  }
}
