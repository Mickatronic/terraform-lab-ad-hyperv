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

# --- La VM de cette variante ----------------------------------------------------------
# Une seule VM : une variable par réglage, sans map ni boucle.
# (La variante 03, avec deux VMs, montre la version « en boucle » avec for_each.)

variable "vm_name" {
  type        = string
  description = "Nom de la VM dans Hyper-V (préfixé pour ne pas entrer en collision avec les autres LABs)"
  default     = "L01-SRV01"
}

variable "computer_name" {
  type        = string
  description = "Nom de l'ordinateur dans Windows (15 caractères maximum)"
  default     = "SRV01"
}

variable "cpus" {
  type    = number
  default = 2
}

# Mémoire DYNAMIQUE (en Mo) : Hyper-V donne « startup » au démarrage, puis ajuste
# entre « min » et « max » selon les besoins réels de la VM.
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

variable "ip_address" {
  type    = string
  default = "192.168.101.20"
}
