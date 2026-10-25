# Alternative au shutdown_command : sysprep manuel.
# Par défaut, Packer lance déjà sysprep via `shutdown_command` dans le .pkr.hcl.
# Si vous préférez l'appeler depuis un provisioner "powershell", retirez le shutdown_command
# et remplacez-le par `shutdown /s /t 10`.
& "$env:SystemRoot\System32\Sysprep\sysprep.exe" /generalize /oobe /shutdown /quiet
