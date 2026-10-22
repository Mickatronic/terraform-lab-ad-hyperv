# =============================================================================
# configuration.tf : ce qui se passe DANS Windows, une fois la VM démarrée.
#
# terraform_data est une ressource « vide » qui sert de support à un provisioner.
# Le provisioner local-exec lance un script PowerShell SUR L'HÔTE ; ce script parle
# à la VM par PowerShell Direct (Invoke-Command -VMName), sans passer par le réseau.
#
# Le provisioner ne s'exécute qu'à la CRÉATION de la ressource. triggers_replace
# force sa recréation (donc une nouvelle exécution) si la VM est recréée ou si un
# script change : c'est pour cela que les scripts sont écrits pour être relançables.
# =============================================================================

resource "terraform_data" "dc01" {
  triggers_replace = [
    hyperv_machine_instance.vm["DC01"].id,
    filesha1("${path.module}/scripts/configure-dc01.ps1"),
    filesha1("${path.module}/scripts/New-LabTiering.ps1"),
    filesha1("${path.module}/scripts/tiering-comptes.csv"),
    filesha1("${path.module}/scripts/LabHelpers.psm1"),
  ]

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = join(" ", [
      "& '${abspath(path.module)}/scripts/configure-dc01.ps1'",
      "-VMName '${local.vm_names["DC01"]}' -ComputerName 'DC01'",
      "-IPAddress '${var.vms["DC01"].ip}' -PrefixLength ${var.prefix_length}",
      "-DomainName '${var.domain_name}' -NetbiosName '${var.netbios_name}' -AdminUser '${var.admin_user}'",
    ])

    # Le mot de passe passe par une variable d'environnement : il n'apparaît ni dans la
    # ligne de commande ni dans la sortie de terraform (variable « sensitive »).
    environment = {
      LAB_ADMIN_PASSWORD = var.admin_password
    }
  }
}
