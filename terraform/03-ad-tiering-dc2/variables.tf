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
  default     = "C:\\VMS\\vms\\03-ad-tiering-dc2"
}

variable "lab_prefix" {
  type        = string
  description = "Préfixe des noms de VM dans Hyper-V (le nom Windows, lui, reste sans préfixe)"
  default     = "L03"
}

variable "switch_name" {
  type    = string
  default = "L03-Internal"
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

# --- Accès Internet (NAT sur l'hôte) -----------------------------------------------------

variable "gateway_ip" {
  type        = string
  description = "Adresse de l'hôte sur le switch interne = passerelle des VMs"
  default     = "192.168.103.1"
}

variable "nat_prefix" {
  type        = string
  description = "Plage traduite par le NAT de l'hôte (une seule règle NAT pour toutes les variantes)"
  default     = "192.168.96.0/19"
}

variable "dns_forwarders" {
  type        = list(string)
  description = "DNS publics utilisés pour les noms Internet (à remplacer par le DNS de votre box ou de l'établissement si besoin)"
  default     = ["1.1.1.1", "8.8.8.8"]
}

# --- Domaine Active Directory --------------------------------------------------------

variable "domain_name" {
  type        = string
  description = "Nom DNS du domaine (racine de la forêt)"
  default     = "lab.local"
}

variable "netbios_name" {
  type        = string
  description = "Nom NetBIOS du domaine (le « LAB » de LAB\\Administrateur)"
  default     = "LAB"
}

# --- Les VMs de cette variante ------------------------------------------------------
# La clé de la map est le nom Windows de la machine.
#
# ATTENTION RAM : l'hôte n'a qu'environ 2,4 Go libres. Deux VMs à 1 Go au démarrage
# (2 Go en tout) passent tout juste. Si Hyper-V refuse de démarrer DC02
# (« mémoire insuffisante »), fermez des applications sur l'hôte ou descendez
# memory_startup_mb à 768 (le démarrage et la promotion seront plus lents).

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
    DC01 = { cpus = 2, memory_startup_mb = 1024, memory_min_mb = 512, memory_max_mb = 1536, ip = "192.168.103.10" }
    DC02 = { cpus = 2, memory_startup_mb = 1024, memory_min_mb = 512, memory_max_mb = 1536, ip = "192.168.103.11" }
  }
}
