# =============================================================================
# main.tf : l'INFRASTRUCTURE Hyper-V, plus le CD de réponse propre à la VM.
#
# Nouveauté de cette variante : le nom et l'IP de Windows ne sont plus posés APRÈS le démarrage
# par un script, mais AU 1er démarrage par un Autounattend.xml gravé sur un CD.
#
#   unattend/Autounattend.xml.tftpl  --templatefile()-->  texte XML propre à la VM
#        --> data.archive_file.unattend     (zip contenant Autounattend.xml)
#        --> hyperv_iso_image.unattend      (ISO créé sur l'hôte par le provider hyperv)
#        --> hyperv_machine_instance.vm     (ISO monté dans le lecteur DVD, puis démarrage)
#
# hyperv_network_switch.lab ──┐
# hyperv_vhd.os ──────────────┼──>  hyperv_machine_instance.vm
# hyperv_iso_image.unattend ──┘
# =============================================================================

locals {
  # MAC au format attendu par l'Autounattend : 00-15-5D-06-06-20
  mac_unattend = upper(join("-", regexall("..", var.mac_address)))

  # Le fichier de réponse de CETTE VM : le modèle complété avec ses valeurs.
  unattend_xml = templatefile("${path.module}/unattend/Autounattend.xml.tftpl", {
    computer_name  = var.computer_name
    time_zone      = var.time_zone
    mac_address    = local.mac_unattend
    ip_address     = var.ip_address
    prefix_length  = var.prefix_length
    gateway_ip     = var.gateway_ip
    dns_servers    = var.dns_servers
    admin_password = var.admin_password
  })
}

# Switch interne, identique à la variante 01.
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

# --- Le CD de réponse -------------------------------------------------------------------

# 1. Un zip contenant un seul fichier, Autounattend.xml, écrit directement depuis le texte
#    généré (bloc source { content }) : pas de fichier intermédiaire à gérer.
data "archive_file" "unattend" {
  type        = "zip"
  output_path = "${path.module}/build/unattend-${var.vm_name}.zip"

  source {
    content  = local.unattend_xml
    filename = "Autounattend.xml"
  }
}

# 2. Le provider hyperv transforme ce zip en ISO sur l'hôte (pas besoin d'oscdimg).
#    source_zip_file_path_hash : si le contenu du zip change, l'ISO est regravé.
resource "hyperv_iso_image" "unattend" {
  volume_name               = "UNATTEND"
  source_zip_file_path      = data.archive_file.unattend.output_path
  source_zip_file_path_hash = data.archive_file.unattend.output_sha
  destination_iso_file_path = "${var.vm_root_path}\\${var.vm_name}\\unattend.iso"
  iso_media_type            = "cdrom"
  iso_file_system_type      = "iso9660|joliet"

  # Le dossier de la VM est créé avec son disque : on attend donc celui-ci.
  depends_on = [hyperv_vhd.os]
}

# --- Le disque et la VM ---------------------------------------------------------------------

# « Version » du fichier de réponse : change dès que son contenu change.
# Sert uniquement de déclencheur au remplacement du disque (voir hyperv_vhd.os).
resource "terraform_data" "unattend_version" {
  input = sha1(local.unattend_xml)
}

# Copie COMPLÈTE de l'image « sans unattend ».
resource "hyperv_vhd" "os" {
  path   = "${var.vm_root_path}\\${var.vm_name}\\${var.vm_name}.vhdx"
  source = var.golden_image_vhdx

  # L'Autounattend n'est lu qu'au TOUT PREMIER démarrage. Si on change le nom ou l'IP,
  # regraver le CD ne suffit pas : il faut repartir d'un disque neuf (et donc d'une VM neuve).
  lifecycle {
    replace_triggered_by = [terraform_data.unattend_version]
  }
}

resource "hyperv_machine_instance" "vm" {
  name            = var.vm_name
  generation      = 2
  processor_count = var.cpus
  path            = var.vm_root_path
  state           = "Running"

  dynamic_memory       = true
  memory_startup_bytes = var.memory_startup_mb * 1024 * 1024
  memory_minimum_bytes = var.memory_min_mb * 1024 * 1024
  memory_maximum_bytes = var.memory_max_mb * 1024 * 1024

  # L'IP est fixe mais posée par Windows pendant specialize : on n'attend pas Hyper-V.
  wait_for_state_timeout = 60
  wait_for_ips_timeout   = 0

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"

    # Démarrer sur le DISQUE : le CD n'est pas amorçable, il ne contient que l'Autounattend.xml.
    boot_order {
      boot_type           = "HardDiskDrive"
      controller_number   = 0
      controller_location = 0
    }
    boot_order {
      boot_type           = "DvdDrive"
      controller_number   = 0
      controller_location = 1
    }
  }

  # MAC fixe : c'est elle que l'Autounattend utilise pour reconnaître la carte.
  network_adaptors {
    name                = "eth0"
    switch_name         = hyperv_network_switch.lab.name
    dynamic_mac_address = false
    static_mac_address  = upper(var.mac_address)
  }

  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.os.path
  }

  # Le CD de réponse, sur le même contrôleur SCSI que le disque (emplacement 1).
  dvd_drives {
    controller_number   = 0
    controller_location = 1
    path                = hyperv_iso_image.unattend.destination_iso_file_path
  }

  # VM neuve quand le disque est remplacé (voir hyperv_vhd.os).
  lifecycle {
    replace_triggered_by = [hyperv_vhd.os]
  }
}
