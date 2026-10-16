variable "iso_path" {
  type        = string
  description = "Chemin local de l'ISO Windows Server 2025"
  default     = "C:/VMS/images/windows2025-noprompt.iso"
}

variable "iso_checksum" {
  type        = string
  description = "Checksum de l'ISO, ex: sha256:abcd... (ou 'none' en LAB)"
  default     = "none"
}

variable "switch_name" {
  type        = string
  description = "Switch Hyper-V utilisé pendant le build (doit donner accès à Internet pour Windows Update)"
  default     = "Default Switch"
}

variable "vm_name" {
  type    = string
  default = "ws2025-golden"
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory_mb" {
  type    = number
  default = 4096
}

variable "disk_size_mb" {
  type    = number
  default = 61440 # 60 Go (dynamique)
}

variable "output_dir" {
  type    = string
  default = "C:/VMS/images/ws2025"
}

variable "admin_password" {
  type        = string
  description = "Doit correspondre au mot de passe défini dans Autounattend.xml"
  default     = "P@ssw0rd!"
  sensitive   = true
}
