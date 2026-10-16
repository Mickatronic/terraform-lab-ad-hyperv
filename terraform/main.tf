# Switch interne : les VMs se voient entre elles et avec l'hôte, sans accès Internet.
# (Pour Internet : ajouter un NAT sur l'hôte, ou utiliser un switch externe.)
resource "hyperv_network_switch" "lab" {
  name                                    = var.switch_name
  notes                                   = "Switch interne du LAB AD"
  allow_management_os                     = true
  enable_embedded_teaming                 = false
  enable_iov                              = false
  enable_packet_direct                    = false
  minimum_bandwidth_mode                  = "None"
  switch_type                             = "Internal"
  default_flow_minimum_bandwidth_absolute = 0
  default_flow_minimum_bandwidth_weight   = 0
}

# Un disque par VM, copie de l'image Packer.
resource "hyperv_vhd" "os" {
  for_each = var.vms

  path   = "${var.vm_root_path}\\${each.key}\\${each.key}.vhdx"
  source = var.golden_image_vhdx
}

resource "hyperv_machine_instance" "vm" {
  for_each = var.vms

  name                 = each.key
  generation           = 2
  processor_count      = each.value.cpus
  static_memory        = true
  memory_startup_bytes = each.value.memory_mb * 1024 * 1024
  path                 = var.vm_root_path
  state                = "Running"

  # Pas d'attente d'adresse IP : le switch interne n'a pas de DHCP, les VMs n'ont pas d'IP au démarrage.
  wait_for_state_timeout = 60
  wait_for_ips_timeout   = 0

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"
  }

  network_adaptors {
    name        = "eth0"
    switch_name = hyperv_network_switch.lab.name
  }

  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.os[each.key].path
  }
}
