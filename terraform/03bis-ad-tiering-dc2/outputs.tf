output "dc01" {
  description = "DC01 : nom Hyper-V, nom Windows et adresse IP"
  value       = "${hyperv_machine_instance.dc01.name} (Windows : ${var.vms["DC01"].name}, IP ${var.vms["DC01"].ip})"
}

output "dc02" {
  description = "DC02 : nom Hyper-V, nom Windows et adresse IP"
  value       = "${hyperv_machine_instance.dc02.name} (Windows : ${var.vms["DC02"].name}, IP ${var.vms["DC02"].ip})"
}

output "domaine" {
  value = "${var.domain_name} (NetBIOS ${var.netbios_name})"
}

output "connexion_dc01" {
  description = "Pour ouvrir une session sur DC01 depuis l'hôte (PowerShell administrateur)"
  value       = "Enter-PSSession -VMName ${hyperv_machine_instance.dc01.name} -Credential ${var.netbios_name}\\${var.admin_user}"
}

output "connexion_dc02" {
  value = "Enter-PSSession -VMName ${hyperv_machine_instance.dc02.name} -Credential ${var.netbios_name}\\${var.admin_user}"
}

output "verification_replication" {
  description = "Commandes à lancer DANS une session sur DC01 ou DC02"
  value       = ["Get-ADDomainController -Filter * | Format-Table HostName, IPv4Address, IsGlobalCatalog", "repadmin /replsummary", "netdom query fsmo"]
}
