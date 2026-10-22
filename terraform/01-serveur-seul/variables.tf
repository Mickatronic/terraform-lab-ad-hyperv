# --- Accès à l'hôte Hyper-V (provider) ----------------------------------------

variable "host_user" {
  type        = string
  description = "Compte Windows local administrateur de l'hôte (pour WinRM)"
}

variable "host_password" {
  type      = string
  sensitive = true
}

# --- Image et emplacement des VMs ----------------------------------------------

variable "golden_image_vhdx" {
  type        = string
  description = "VHDX Server Core produit par Packer (packer\\windows-server-2025-core)"
  default     = "C:\\VMS\\images\\ws2025-core\\Virtual Hard Disks\\ws2025-core-golden.vhdx"
}

variable "vm_root_path" {
  type        = string
  description = "Dossier où seront stockés les VMs et leurs disques"
  default     = "C:\\VMS\\vms\\01-serveur-seul"
}

variable "lab_prefix" {
  type        = string
  description = "Préfixe des noms de VM dans Hyper-V (le nom Windows, lui, reste sans préfixe)"
  default     = "L01"
}

variable "switch_name" {
  type    = string
  default = "L01-Internal"
}

# --- Compte Administrateur des VMs ---------------------------------------------

variable "admin_user" {
  type        = string
  description = "Compte local de l'image (ISO française : « Administrateur »)"
  default     = "Administrateur"
}

variable "admin_password" {
  type        = string
  description = "Mot de passe défini par sysprep-unattend.xml dans l'image Packer (LAB uniquement)"
  sensitive   = true
  default     = "P@ssw0rd!"
}

# --- Réseau du LAB ---------------------------------------------------------------

variable "prefix_length" {
  type    = number
  default = 24
}

# --- Les VMs de cette variante ------------------------------------------------------
# La clé de la map (SRV01) est le nom Windows de la machine.

variable "vms" {
  description = "Définition des VMs du LAB"
  type = map(object({
    cpus              = number
    memory_startup_mb = number
    memory_min_mb     = number
    memory_max_mb     = number
    ip                = string
  }))
  default = {
    SRV01 = { cpus = 2, memory_startup_mb = 1024, memory_min_mb = 512, memory_max_mb = 2048, ip = "192.168.101.20" }
  }
}
