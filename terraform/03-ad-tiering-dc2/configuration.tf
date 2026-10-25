# =============================================================================
# configuration.tf : ce qui se passe DANS Windows, une fois les VMs démarrées.
#
# terraform_data est une ressource « vide » qui sert de support à un provisioner.
# Le provisioner local-exec lance un script PowerShell SUR L'HÔTE ; ce script parle
# aux VMs par PowerShell Direct (Invoke-Command -VMName), sans passer par le réseau.
#
# Le provisioner ne s'exécute qu'à la CRÉATION de la ressource. triggers_replace
# force sa recréation (donc une nouvelle exécution) si la VM est recréée ou si un
# script change : c'est pour cela que les scripts sont écrits pour être relançables.
# =============================================================================

# --- 1. DC01 : nouvelle forêt + modèle de tiering (identique à la variante 02) -----------

resource "terraform_data" "dc01" {
  triggers_replace = [
    hyperv_machine_instance.vm["DC01"].id,
    filesha1("${path.module}/scripts/configure-dc01.ps1"),
    filesha1("${path.module}/scripts/New-LabTiering.ps1"),
    filesha1("${path.module}/scripts/tiering-comptes.csv"),
    filesha1("${path.module}/scripts/LabHelpers.psm1"),
  ]

  provisioner "local-exec" {
    # -NonInteractive : si quelque chose demande une saisie (identifiants...), le script échoue
    # avec un message d'erreur au lieu d'ouvrir une fenêtre et de bloquer Terraform.
    interpreter = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"]
    command = join(" ", [
      "& '${abspath(path.module)}/scripts/configure-dc01.ps1'",
      "-VMName '${local.vm_names["DC01"]}' -ComputerName 'DC01'",
      "-IPAddress '${var.vms["DC01"].ip}' -PrefixLength ${var.prefix_length}",
      "-DomainName '${var.domain_name}' -NetbiosName '${var.netbios_name}' -AdminUser '${var.admin_user}'",
    ])
    environment = {
      LAB_ADMIN_PASSWORD = nonsensitive(var.admin_password)
    }
  }
}

# --- 2. DC02 : jonction au domaine puis promotion en DC supplémentaire ---------------------

resource "terraform_data" "dc02" {
  # depends_on : Terraform ne sait pas tout seul que DC02 a besoin d'un domaine qui
  # FONCTIONNE (il ne voit que des ressources). On lui impose donc l'ordre : DC02 n'est
  # configuré qu'une fois la configuration de DC01 terminée avec succès.
  depends_on = [terraform_data.dc01]

  triggers_replace = [
    hyperv_machine_instance.vm["DC02"].id,
    filesha1("${path.module}/scripts/configure-dc02.ps1"),
    filesha1("${path.module}/scripts/LabHelpers.psm1"),
  ]

  provisioner "local-exec" {
    # -NonInteractive : si quelque chose demande une saisie (identifiants...), le script échoue
    # avec un message d'erreur au lieu d'ouvrir une fenêtre et de bloquer Terraform.
    interpreter = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"]
    command = join(" ", [
      "& '${abspath(path.module)}/scripts/configure-dc02.ps1'",
      "-VMName '${local.vm_names["DC02"]}' -ComputerName 'DC02'",
      "-IPAddress '${var.vms["DC02"].ip}' -PrefixLength ${var.prefix_length}",
      "-PartnerVMName '${local.vm_names["DC01"]}' -PartnerIPAddress '${var.vms["DC01"].ip}'",
      "-DomainName '${var.domain_name}' -NetbiosName '${var.netbios_name}' -AdminUser '${var.admin_user}'",
    ])
    environment = {
      LAB_ADMIN_PASSWORD = nonsensitive(var.admin_password)
    }
  }
}
