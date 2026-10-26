# =============================================================================
# configuration.tf : ce qui se passe une fois la VM démarrée.
#
# Différence avec la variante 01 : il n'y a PLUS RIEN à configurer dans Windows.
# Le nom, l'IP, la passerelle et le DNS viennent de l'Autounattend.xml du CD (main.tf).
# Le script lancé ici se contente d'ATTENDRE la fin du 1er démarrage et de VÉRIFIER le résultat.
# =============================================================================

# --- 0. Accès Internet : passerelle sur l'hôte + NAT (voir scripts/New-LabNat.ps1) -----------

resource "terraform_data" "nat" {
  triggers_replace = [
    hyperv_network_switch.lab.id,
    filesha1("${path.module}/scripts/New-LabNat.ps1"),
  ]

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"]
    command = join(" ", [
      "& '${abspath(path.module)}/scripts/New-LabNat.ps1'",
      "-SwitchName '${hyperv_network_switch.lab.name}' -GatewayIP '${var.gateway_ip}'",
      "-PrefixLength ${var.prefix_length} -NatPrefix '${var.nat_prefix}'",
    ])
  }
}

# --- 1. Vérification du 1er démarrage ---------------------------------------------------------

resource "terraform_data" "verification" {
  depends_on = [terraform_data.nat]

  triggers_replace = [
    hyperv_machine_instance.vm.id,
    filesha1("${path.module}/scripts/verifier-serveur.ps1"),
    filesha1("${path.module}/scripts/LabHelpers.psm1"),
  ]

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-Command"]
    command = join(" ", [
      "& '${abspath(path.module)}/scripts/verifier-serveur.ps1'",
      "-VMName '${var.vm_name}' -ComputerName '${var.computer_name}'",
      "-IPAddress '${var.ip_address}' -AdminUser '${var.admin_user}'",
    ])

    # Mot de passe par variable d'environnement (voir la variante 01 pour nonsensitive()).
    environment = {
      LAB_ADMIN_PASSWORD = nonsensitive(var.admin_password)
    }
  }
}
