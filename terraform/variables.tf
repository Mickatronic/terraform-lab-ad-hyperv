variable "host_user" {
  type        = string
  description = "Compte Windows local administrateur de l'hôte (pour WinRM)"
}

variable "host_password" {
  type      = string
  sensitive = true
}

variable "golden_image_vhdx" {
  type        = string
  description = "VHDX produit par Packer"
  default     = "C:\\VMS\\images\\ws2025\\Virtual Hard Disks\\ws2025-golden.vhdx"
}

variable "vm_root_path" {
  type        = string
  description = "Dossier où seront stockés les VMs et leurs disques"
  default     = "C:\\VMS\\vms"
}

variable "switch_name" {
  type    = string
  default = "LAB-Internal"
}

variable "vms" {
  description = "Définition des VMs du LAB"
  type = map(object({
    cpus      = number
    memory_mb = number
  }))
  default = {
    DC01  = { cpus = 2, memory_mb = 2048 }
    SRV01 = { cpus = 2, memory_mb = 2048 }
  }
}
