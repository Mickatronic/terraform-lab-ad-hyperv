# =============================================================================
# main.tf : l'INFRASTRUCTURE Hyper-V (switch, disque, VM).
# La configuration de Windows DANS la VM est dans configuration.tf.
#
# Trois ressources, créées dans cet ordre (Terraform le déduit des références) :
#   hyperv_network_switch.lab  ─┐
#                               ├─>  hyperv_machine_instance.vm
#   hyperv_vhd.os              ─┘
# =============================================================================

# Switch interne : la VM voit l'hôte (et les autres VMs du switch), sans accès Internet.
# Pas de DHCP sur ce switch : l'adresse IP est fixée par le script de configuration.
resource "hyperv_network_switch" "lab" {
  name                                    = var.switch_name
  notes                                   = "Switch interne du LAB"
  allow_management_os                     = true
  enable_embedded_teaming                 = false
  enable_iov                              = false
  enable_packet_direct                    = false
  minimum_bandwidth_mode                  = "None"
  switch_type                             = "Internal"
  default_flow_minimum_bandwidth_absolute = 0
  default_flow_minimum_bandwidth_weight   = 0
}

# Le disque de la VM : copie COMPLÈTE de l'image Packer Server Core
# (quelques Go, d'où le timeout de 900 s dans providers.tf).
resource "hyperv_vhd" "os" {
  path   = "${var.vm_root_path}\\${var.vm_name}\\${var.vm_name}.vhdx"
  source = var.golden_image_vhdx
}

resource "hyperv_machine_instance" "vm" {
  name            = var.vm_name
  generation      = 2
  processor_count = var.cpus
  path            = var.vm_root_path
  state           = "Running"

  # Mémoire dynamique : l'hôte n'a que peu de RAM libre.
  # Un Server Core au repos consomme environ 600 à 800 Mo.
  dynamic_memory       = true
  memory_startup_bytes = var.memory_startup_mb * 1024 * 1024
  memory_minimum_bytes = var.memory_min_mb * 1024 * 1024
  memory_maximum_bytes = var.memory_max_mb * 1024 * 1024

  # Pas d'attente d'adresse IP : pas de DHCP, la VM n'a pas d'IP au démarrage.
  wait_for_state_timeout = 60
  wait_for_ips_timeout   = 0

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"
  }

  # Référence au switch : c'est elle qui oblige Terraform à créer le switch AVANT la VM.
  network_adaptors {
    name        = "eth0"
    switch_name = hyperv_network_switch.lab.name
  }

  # Référence au disque : même chose, le disque est créé avant la VM.
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.os.path
  }
}
