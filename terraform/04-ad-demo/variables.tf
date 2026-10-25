variable "host_user" {
  type = string
}

variable "host_password" {
  type      = string
  sensitive = true
}
