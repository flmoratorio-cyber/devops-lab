variable "external_port" {
  description = "Host port published for the container"
  type        = number
  default     = 8082
}

variable "container_name" {
  description = "Container name"
  type        = string
  default     = "nginx-server"
}
