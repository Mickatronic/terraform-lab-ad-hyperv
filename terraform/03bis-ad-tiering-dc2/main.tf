# =============================================================================
# main.tf : l'INFRASTRUCTURE Hyper-V (switch, disques, VMs).
# La configuration de Windows DANS les VMs est dans configuration.tf.
#
# Même résultat que la variante 03, mais SANS BOUCLE : chaque VM est écrite en entier.
# Toutes les valeurs d'une VM (nom, switch, dossier, CPU, mémoire) viennent de la map var.vms
# (variables.tf), lue par sa clé : var.vms["DC01"].id, var.vms["DC02"].cpus... Cinq ressources :
#
#   hyperv_network_switch.lab ──┬──>  hyperv_machine_instance.dc01  <──  hyperv_vhd.dc01
#                               └──>  hyperv_machine_instance.dc02  <──  hyperv_vhd.dc02
# =============================================================================

# Switch interne : les VMs se voient entre elles et avec l'hôte.
# Pas de DHCP sur ce switch : les adresses IP sont fixées par les scripts de configuration.
resource "hyperv_network_switch" "lab" {
  name                                    = var.switch_name
  notes                                   = "Switch interne du LAB 03 bis"
  allow_management_os                     = true
  enable_embedded_teaming                 = false
  enable_iov                              = false
  enable_packet_direct                    = false
  minimum_bandwidth_mode                  = "None"
  switch_type                             = "Internal"
  default_flow_minimum_bandwidth_absolute = 0
  default_flow_minimum_bandwidth_weight   = 0
}

# =============================================================================
# DC01
# =============================================================================

# Disque de DC01 : copie COMPLÈTE de l'image Packer Server Core
# (quelques Go, d'où le timeout de 900 s dans providers.tf).
resource "hyperv_vhd" "dc01" {
  path   = "${var.vms["DC01"].path}\\${var.vms["DC01"].id}\\${var.vms["DC01"].id}.vhdx"
  source = var.golden_image_vhdx
}

resource "hyperv_machine_instance" "dc01" {
  name            = var.vms["DC01"].id
  generation      = 2
  processor_count = var.vms["DC01"].cpus
  path            = var.vms["DC01"].path
  state           = "Running"

  # Mémoire dynamique : l'hôte n'a que peu de RAM libre.
  # Un Server Core au repos consomme environ 600 à 800 Mo.
  dynamic_memory       = true
  memory_startup_bytes = var.vms["DC01"].memory_startup_mb * 1024 * 1024
  memory_minimum_bytes = var.vms["DC01"].memory_min_mb * 1024 * 1024
  memory_maximum_bytes = var.vms["DC01"].memory_max_mb * 1024 * 1024

  # Pas d'attente d'adresse IP : pas de DHCP, la VM n'a pas d'IP au démarrage.
  wait_for_state_timeout = 60
  wait_for_ips_timeout   = 0

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"
  }

  # Le nom du switch vient de la map (une simple chaîne) : Terraform ne voit donc plus de lien
  # avec la ressource hyperv_network_switch.lab. depends_on lui impose de créer le switch AVANT la VM.
  depends_on = [hyperv_network_switch.lab]

  network_adaptors {
    name        = "eth0"
    switch_name = var.vms["DC01"].switch
  }

  # Référence au disque de DC01 : créé avant la VM.
  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.dc01.path
  }
}

# =============================================================================
# DC02 : même définition que DC01, avec la clé "DC02" et son propre disque.
# =============================================================================

resource "hyperv_vhd" "dc02" {
  path   = "${var.vms["DC02"].path}\\${var.vms["DC02"].id}\\${var.vms["DC02"].id}.vhdx"
  source = var.golden_image_vhdx
}

resource "hyperv_machine_instance" "dc02" {
  name            = var.vms["DC02"].id
  generation      = 2
  processor_count = var.vms["DC02"].cpus
  path            = var.vms["DC02"].path
  state           = "Running"

  dynamic_memory       = true
  memory_startup_bytes = var.vms["DC02"].memory_startup_mb * 1024 * 1024
  memory_minimum_bytes = var.vms["DC02"].memory_min_mb * 1024 * 1024
  memory_maximum_bytes = var.vms["DC02"].memory_max_mb * 1024 * 1024

  wait_for_state_timeout = 60
  wait_for_ips_timeout   = 0

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"
  }

  depends_on = [hyperv_network_switch.lab]

  network_adaptors {
    name        = "eth0"
    switch_name = var.vms["DC02"].switch
  }

  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.dc02.path
  }
}
