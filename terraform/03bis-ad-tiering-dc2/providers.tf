# Le provider pilote Hyper-V via WinRM sur l'hôte (ici, la machine locale).
provider "hyperv" {
  user     = var.host_user
  password = var.host_password
  host     = "127.0.0.1"
  port     = 5985
  https    = false
  insecure = true
  use_ntlm = true
  # Délai par opération WinRM : la copie d'un VHDX de plusieurs Go dépasse largement les 30 s par défaut.
  timeout = "900s"
}
