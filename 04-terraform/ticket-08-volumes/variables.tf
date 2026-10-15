variable "container_name" {
  type    = string
  default = "nginx-persist"
}

variable "external_port" {
  description = "Change this value to force a container replacement (-/+) in the persistence test"
  type        = number
  default     = 8085
}
