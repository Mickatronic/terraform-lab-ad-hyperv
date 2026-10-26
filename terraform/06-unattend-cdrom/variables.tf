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
  description = "VHDX produit par packer\\windows-server-2025-core-sans-unattend (image SANS fichier de réponse sysprep)"
  default     = "C:\\VMS\\images\\ws2025-core-sans-unattend\\Virtual Hard Disks\\ws2025-core-sans-unattend.vhdx"
}

variable "vm_root_path" {
  type        = string
  description = "Dossier où seront stockés la VM, son disque et son ISO de réponse"
  default     = "C:\\VMS\\vms\\06-unattend-cdrom"
}

variable "switch_name" {
  type    = string
  default = "L06-Internal"
}

# --- Compte Administrateur des VMs ---------------------------------------------

variable "admin_user" {
  type        = string
  description = "Compte local de l'image (ISO française : « Administrateur »)"
  default     = "Administrateur"
}

variable "admin_password" {
  type        = string
  description = "Mot de passe écrit dans l'Autounattend.xml du CD (LAB uniquement : il y est en clair)"
  sensitive   = true
  default     = "P@ssw0rd!"
}

variable "time_zone" {
  type        = string
  description = "Fuseau horaire Windows (liste : tzutil /l)"
  default     = "Romance Standard Time"
}

# --- Réseau du LAB ---------------------------------------------------------------

variable "prefix_length" {
  type    = number
  default = 24
}

variable "gateway_ip" {
  type        = string
  description = "Adresse de l'hôte sur le switch interne = passerelle des VMs"
  default     = "192.168.106.1"
}

variable "nat_prefix" {
  type        = string
  description = "Plage traduite par le NAT de l'hôte (une seule règle NAT pour toutes les variantes)"
  default     = "192.168.96.0/19"
}

variable "dns_servers" {
  type        = list(string)
  description = "Serveurs DNS de la VM (DNS publics, à remplacer par celui de l'établissement si besoin)"
  default     = ["1.1.1.1", "8.8.8.8"]
}

# --- La VM de cette variante ----------------------------------------------------------

variable "vm_name" {
  type        = string
  description = "Nom de la VM dans Hyper-V (préfixé pour ne pas entrer en collision avec les autres LABs)"
  default     = "L06-SRV01"
}

variable "computer_name" {
  type        = string
  description = "Nom de l'ordinateur dans Windows (15 caractères maximum), posé dès le 1er démarrage"
  default     = "SRV01"
}

variable "ip_address" {
  type    = string
  default = "192.168.106.20"
}

# Adresse MAC FIXE : l'Autounattend.xml désigne la carte réseau par son adresse MAC
# (Identifier du composant Microsoft-Windows-TCPIP). Avec une MAC dynamique, on ne la
# connaîtrait qu'après la création de la VM, trop tard pour graver le CD.
# 00155D = préfixe réservé à Hyper-V. 12 chiffres hexadécimaux, sans séparateur.
variable "mac_address" {
  type    = string
  default = "00155D060620"

  validation {
    condition     = can(regex("^[0-9A-Fa-f]{12}$", var.mac_address))
    error_message = "mac_address : 12 chiffres hexadécimaux sans séparateur, par exemple 00155D060620."
  }
}

variable "cpus" {
  type    = number
  default = 2
}

variable "memory_startup_mb" {
  type    = number
  default = 1024
}

variable "memory_min_mb" {
  type    = number
  default = 512
}

variable "memory_max_mb" {
  type    = number
  default = 2048
}
