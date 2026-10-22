output "vms" {
  description = "VMs créées : nom Hyper-V et adresse IP"
  value       = { for k, v in var.vms : k => { vm_hyperv = local.vm_names[k], ip = v.ip } }
}

output "connexion" {
  description = "Pour ouvrir une session sur la VM depuis l'hôte (PowerShell administrateur)"
  value       = { for k, v in var.vms : k => "Enter-PSSession -VMName ${local.vm_names[k]} -Credential ${var.admin_user}" }
}
