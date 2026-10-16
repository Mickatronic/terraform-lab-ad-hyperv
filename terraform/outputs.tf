output "vms" {
  description = "VMs créées"
  value       = { for k, v in hyperv_machine_instance.vm : k => v.state }
}
