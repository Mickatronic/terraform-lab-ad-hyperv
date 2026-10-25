output "vm" {
  description = "Nom de la VM dans Hyper-V et dans Windows"
  value       = "${var.vm_name} (Windows : ${var.computer_name})"
}

output "ip" {
  value = var.ip_address
}

output "domaine" {
  value = "${var.domain_name} (NetBIOS ${var.netbios_name})"
}

output "connexion" {
  description = "Pour ouvrir une session sur le DC depuis l'hôte (PowerShell administrateur)"
  value       = "Enter-PSSession -VMName ${var.vm_name} -Credential ${var.netbios_name}\\${var.admin_user}"
}

output "verification" {
  description = "Commande à lancer DANS la session pour voir l'arborescence de tiering"
  value       = "Get-ADOrganizationalUnit -Filter * | Sort-Object DistinguishedName | Format-Table Name, DistinguishedName"
}
