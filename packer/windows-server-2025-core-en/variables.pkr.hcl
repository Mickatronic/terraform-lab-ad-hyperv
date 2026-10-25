variable "iso_path" {
  type        = string
  description = "Chemin local de l'ISO Windows Server 2025 ANGLAIS (en-US) (le même ISO contient les éditions Core et Desktop Experience)"
  default     = "C:/VMS/images/windows2025-en-noprompt.iso"
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
  default = "ws2025-core-en-golden"
}

variable "cpus" {
  type    = number
  default = 2
}

# Même valeur que la version Desktop Experience (qui, elle, va au bout du sysprep).
# 2 Go suffisent pour faire tourner Core, mais on garde 4 Go pendant le build.
variable "memory_mb" {
  type    = number
  default = 4096
}

variable "disk_size_mb" {
  type    = number
  default = 40960 # 40 Go (dynamique) : Core occupe environ 8 Go après installation
}

variable "output_dir" {
  type    = string
  default = "C:/VMS/images/ws2025-core-en"
}

variable "admin_password" {
  type        = string
  description = "Doit correspondre au mot de passe défini dans Autounattend.xml"
  default     = "P@ssw0rd!"
  sensitive   = true
}
