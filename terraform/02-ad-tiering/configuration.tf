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
    hyperv_machine_instance.vm.id,
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
      "-VMName '${var.vm_name}' -ComputerName '${var.computer_name}'",
      "-IPAddress '${var.ip_address}' -PrefixLength ${var.prefix_length}",
      "-DomainName '${var.domain_name}' -NetbiosName '${var.netbios_name}' -AdminUser '${var.admin_user}'",
    ])

    # Le mot de passe passe par une variable d'environnement : il n'apparaît pas dans la ligne
    # de commande. nonsensitive() est nécessaire : avec une valeur « sensitive » dans environment,
    # Terraform masque TOUTE la sortie du script (« output suppressed »), on ne verrait plus les étapes.
    environment = {
      LAB_ADMIN_PASSWORD = nonsensitive(var.admin_password)
    }
  }
}
