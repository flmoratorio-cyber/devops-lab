variable "docker_host" {
  description = "Remote Docker daemon reached over SSH"
  type        = string
  default     = "ssh://<user>@wk1"
}
