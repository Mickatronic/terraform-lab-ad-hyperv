resource "hyperv_network_switch" "lab" {
  name        = "L04-Internal"
  switch_type = "Internal"
}

resource "hyperv_vhd" "os" {
  path   = "C:\\VMS\\vms\\04-ad-demo\\L04-DC01\\L04-DC01.vhdx"
  #source = "C:\\VMS\\images\\ws2025-core\\Virtual Hard Disks\\ws2025-core-golden.vhdx"
  source = "C:\\VMS\\images\\ws2025\\Virtual Hard Disks\\ws2025-golden.vhdx"
}

resource "hyperv_machine_instance" "vm" {
  name                 = "L04-DC01"
  generation           = 2
  processor_count      = 2
  path                 = "C:\\VMS\\vms\\04-ad-demo"
  state                = "Running"
  dynamic_memory       = true
  memory_startup_bytes = 1024 * 1024 * 1024
  memory_minimum_bytes = 512 * 1024 * 1024
  memory_maximum_bytes = 2048 * 1024 * 1024
  wait_for_ips_timeout = 0

  vm_firmware {
    enable_secure_boot   = "On"
    secure_boot_template = "MicrosoftWindows"
  }

  network_adaptors {
    name        = "eth0"
    switch_name = hyperv_network_switch.lab.name
  }

  hard_disk_drives {
    controller_type     = "Scsi"
    controller_number   = 0
    controller_location = 0
    path                = hyperv_vhd.os.path
  }
}

# Une fois la VM créée, Terraform lance dc01.ps1 sur l'hôte.
resource "terraform_data" "dc01" {
  triggers_replace = [hyperv_machine_instance.vm.id]

  provisioner "local-exec" {
    interpreter = ["powershell.exe", "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-File"]
    command     = "${abspath(path.module)}/dc01.ps1"
  }
}
