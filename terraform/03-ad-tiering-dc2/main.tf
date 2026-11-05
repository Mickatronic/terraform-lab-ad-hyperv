# =============================================================================
# main.tf : l'INFRASTRUCTURE Hyper-V (switch, disques, VMs).
# La configuration de Windows DANS les VMs est dans configuration.tf.
# =============================================================================

locals {
  # Nom de chaque VM dans Hyper-V, lu dans le champ « id » de la map var.vms (variables.tf).
  #
  # La boucle se lit ligne par ligne :
  #   for nom_vm, fiche_vm in var.vms :   « pour chaque VM de la map (nom_vm = "DC01", puis "DC02"),
  #                                          avec sa fiche (fiche_vm = { id = ..., name = ..., ... }) »
  #   nom_vm => fiche_vm.id               « retenir : la clé de la VM => son id »
  #
  # Résultat : vm_names = { DC01 = "L03-DC01", DC02 = "L03-DC02" }
  # Ailleurs, local.vm_names["DC01"] donne donc "L03-DC01".
  vm_names = {
    for nom_vm, fiche_vm in var.vms :
    nom_vm => fiche_vm.id
  }
}

# Switch interne : les VMs se voient entre elles et avec l'hôte, sans accès Internet.
# Pas de DHCP sur ce switch : les adresses IP sont fixées par les scripts de configuration.
resource "hyperv_network_switch" "lab" {
  name                                    = var.switch_name
  notes                                   = "Switch interne du LAB 03"
  allow_management_os                     = true
  enable_embedded_teaming                 = false
  enable_iov                              = false
  enable_packet_direct                    = false
  minimum_bandwidth_mode                  = "None"
  switch_type                             = "Internal"
  default_flow_minimum_bandwidth_absolute = 0
  default_flow_minimum_bandwidth_weight   = 0
}

# Un disque par VM : copie COMPLÈTE de l'image Packer Server Core (quelques Go, d'où le timeout du provider).
resource "hyperv_vhd" "os" {
  for_each = var.vms

  path   = "${each.value.path}\\${local.vm_names[each.key]}\\${local.vm_names[each.key]}.vhdx"
  source = var.golden_image_vhdx
}

resource "hyperv_machine_instance" "vm" {
  for_each = var.vms

  name            = local.vm_names[each.key]
  generation      = 2
  processor_count = each.value.cpus
  path            = each.value.path
  state           = "Running"

  # Mémoire DYNAMIQUE : l'hôte n'a que peu de RAM libre. Hyper-V donne « startup » au démarrage,
  # puis ajuste entre « minimum » et « maximum » selon les besoins réels de la VM.
  # Un Server Core au repos consomme environ 600 à 800 Mo.
  dynamic_memory       = true
  memory_startup_bytes = each.value.memory_startup_mb * 1024 * 1024
  memory_minimum_bytes = each.value.memory_min_mb * 1024 * 1024
  memory_maximum_bytes = each.value.memory_max_mb * 1024 * 1024

  # Pas d'attente d'adresse IP : pas de DHCP, la VM n'a pas d'IP au démarrage.
  wait_for_state_timeout = 60
  wait_for_ips_timeout   = 0

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"
  }

  # Le nom du switch vient de la map (une simple chaîne) : Terraform ne voit donc pas de lien
  # avec la ressource hyperv_network_switch.lab. depends_on lui impose de créer le switch AVANT les VMs.
  depends_on = [hyperv_network_switch.lab]

  network_adaptors {
    name        = "eth0"
    switch_name = each.value.switch
  }

  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.os[each.key].path
  }
}
