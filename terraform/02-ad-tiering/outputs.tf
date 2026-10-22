output "vms" {
  description = "VMs créées : nom Hyper-V et adresse IP"
  value       = { for k, v in var.vms : k => { vm_hyperv = local.vm_names[k], ip = v.ip } }
}

output "domaine" {
  value = "${var.domain_name} (NetBIOS ${var.netbios_name})"
}

output "connexion" {
  description = "Pour ouvrir une session sur un DC depuis l'hôte (PowerShell administrateur)"
  value       = { for k, v in var.vms : k => "Enter-PSSession -VMName ${local.vm_names[k]} -Credential ${var.netbios_name}\\${var.admin_user}" }
}

output "verification" {
  description = "Commande à lancer DANS la session pour voir l'arborescence de tiering"
  value       = "Get-ADOrganizationalUnit -Filter * | Sort-Object DistinguishedName | Format-Table Name, DistinguishedName"
}
