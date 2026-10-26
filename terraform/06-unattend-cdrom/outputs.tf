output "vm" {
  description = "Nom de la VM dans Hyper-V et dans Windows"
  value       = "${var.vm_name} (Windows : ${var.computer_name})"
}

output "ip" {
  value = var.ip_address
}

output "cd_de_reponse" {
  description = "ISO monté dans le lecteur DVD de la VM (contient Autounattend.xml)"
  value       = hyperv_iso_image.unattend.destination_iso_file_path
}

output "connexion" {
  description = "Pour ouvrir une session sur la VM depuis l'hôte (PowerShell administrateur)"
  value       = "Enter-PSSession -VMName ${var.vm_name} -Credential ${var.admin_user}"
}
