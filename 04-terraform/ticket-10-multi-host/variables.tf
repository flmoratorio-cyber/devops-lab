variable "host_wk1" {
  type    = string
  default = "ssh://<user>@wk1"
}
variable "host_wk2" {
  type    = string
  default = "ssh://<user>@wk2"
}
variable "host_wk3" {
  type    = string
  default = "ssh://<user>@wk3"
}
variable "host_wk4" {
  type    = string
  default = "ssh://<user>@wk4"
}

variable "port_wk1" {
  type    = number
  default = 8081
}
variable "port_wk2" {
  type    = number
  default = 8082
}
variable "port_wk3" {
  type    = number
  default = 8083
}
variable "port_wk4" {
  type    = number
  default = 8084
}
