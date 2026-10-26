packer {
  required_plugins {
    hyperv = {
      source  = "github.com/hashicorp/hyperv"
      version = ">= 1.1.0"
    }
  }
}

# Variante SANS FICHIER DE RÉPONSE SYSPREP de ../windows-server-2025-core.
# Différences avec l'original :
#   - pas de provisioner "file" pour sysprep-unattend.xml (le fichier n'existe pas ici) ;
#   - 03-register-sysprep-task.ps1 lance sysprep SANS /unattend et efface l'unattend mis en cache
#     par l'installation (C:\Windows\Panther\unattend.xml).
# Au 1er démarrage d'un clone, Windows cherche alors un Autounattend.xml sur un CD/DVD :
# c'est Terraform qui le fournit (terraform-variantes\06-unattend-cdrom), avec le nom et l'IP de la VM.
# ATTENTION : un clone démarré SANS ce CD s'arrête sur l'assistant OOBE (pays, clavier, mot de passe).
source "hyperv-iso" "ws2025core" {
  vm_name   = var.vm_name
  generation = 2

  iso_url      = var.iso_path
  iso_checksum = var.iso_checksum

  cpus                 = var.cpus
  memory               = var.memory_mb
  disk_size            = var.disk_size_mb
  switch_name          = var.switch_name
  enable_secure_boot   = true
  secure_boot_template = "MicrosoftWindows"
  enable_dynamic_memory = false

  # Les fichiers sont gravés dans un CD monté dans la VM (nécessite oscdimg / ADK).
  # Windows Setup y trouve Autounattend.xml automatiquement.
  cd_files = [
    "${path.root}/answer_files/Autounattend.xml",
    "${path.root}/scripts/01-configure-winrm.ps1",
  ]

  # L'ISO utilisé (windows2025-noprompt.iso, créé par scripts/prepare-iso-noprompt.ps1) démarre
  # sans « Press any key to boot from CD or DVD ». Les Espace ci-dessous ne sont qu'une sécurité.
  boot_wait    = "1s"
  boot_command = [join("", [for i in range(20) : "<space><wait500ms>"])]

  communicator   = "winrm"
  winrm_username = "Administrateur" # compte localisé (ISO français), SID 500
  winrm_password = var.admin_password
  winrm_use_ssl  = false
  winrm_insecure = true
  winrm_timeout  = "2h"

  # Même principe que l'original : sysprep lancé par une tâche planifiée détachée (voir script 03).
  shutdown_command = "schtasks /run /tn PackerSysprep"
  shutdown_timeout = "30m"

  output_directory = var.output_dir
}

build {
  name    = "windows-server-2025-core-sans-unattend"
  sources = ["source.hyperv-iso.ws2025core"]

  provisioner "powershell" {
    scripts = [
      "${path.root}/scripts/02-updates-and-tools.ps1",
    ]
  }

  # Diagnostic réseau avant/après redémarrage : si la carte réseau disparaît, on le verra ici.
  provisioner "powershell" {
    inline = [
      "Get-NetAdapter | Format-Table Name,InterfaceDescription,Status -AutoSize | Out-String -Width 200",
      "Get-PnpDevice -Class Net | Format-Table Status,FriendlyName -AutoSize | Out-String -Width 200",
      "ipconfig",
    ]
  }

  provisioner "windows-restart" {
    restart_timeout = "15m"
  }

  provisioner "powershell" {
    inline = [
      "Get-NetAdapter | Format-Table Name,InterfaceDescription,Status -AutoSize | Out-String -Width 200",
      "ipconfig",
    ]
  }

  # Pas de provisioner "file" ici : aucun fichier de réponse n'est déposé dans l'image.

  # Crée la tâche planifiée PackerSysprep déclenchée par shutdown_command.
  provisioner "powershell" {
    scripts = ["${path.root}/scripts/03-register-sysprep-task.ps1"]
  }
}
