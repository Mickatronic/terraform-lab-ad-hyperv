output "vm" {
  description = "Nom de la VM dans Hyper-V et dans Windows"
  value       = "${var.vm_name} (Windows : ${var.computer_name})"
}

output "ip" {
  value = var.ip_address
}

output "connexion" {
  description = "Pour ouvrir une session sur la VM depuis l'hôte (PowerShell administrateur)"
  value       = "Enter-PSSession -VMName ${var.vm_name} -Credential ${var.admin_user}"
}
