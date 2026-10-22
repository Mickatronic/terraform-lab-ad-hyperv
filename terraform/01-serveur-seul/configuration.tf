# =============================================================================
# configuration.tf : ce qui se passe DANS Windows, une fois la VM démarrée.
#
# terraform_data est une ressource « vide » qui sert de support à un provisioner.
# Le provisioner local-exec lance un script PowerShell SUR L'HÔTE ; ce script parle
# à la VM par PowerShell Direct (Invoke-Command -VMName), sans passer par le réseau.
#
# Le provisioner ne s'exécute qu'à la CRÉATION de la ressource. triggers_replace
# force sa recréation (donc une nouvelle exécution) si la VM est recréée ou si le
# script change : c'est pour cela que les scripts sont écrits pour être relançables.
# =============================================================================

resource "terraform_data" "configuration" {
  for_each = var.vms

  triggers_replace = [
    hyperv_machine_instance.vm[each.key].id,
    filesha1("${path.module}/scripts/configure-serveur.ps1"),
    filesha1("${path.module}/scripts/LabHelpers.psm1"),
  ]

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${abspath(path.module)}/scripts/configure-serveur.ps1' -VMName '${local.vm_names[each.key]}' -ComputerName '${each.key}' -IPAddress '${each.value.ip}' -PrefixLength ${var.prefix_length} -AdminUser '${var.admin_user}'"

    # Le mot de passe passe par une variable d'environnement : il n'apparaît ni dans la
    # ligne de commande ni dans la sortie de terraform (variable « sensitive »).
    environment = {
      LAB_ADMIN_PASSWORD = var.admin_password
    }
  }
}
