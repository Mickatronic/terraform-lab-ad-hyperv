#Requires -RunAsAdministrator
# Construit l'image Windows Server 2025 Core SANS fichier de réponse sysprep.
# Même principe que 01-build-image-core.ps1, sur le dossier packer\windows-server-2025-core-sans-unattend.
# Image destinée à terraform\06-unattend-cdrom (le fichier de réponse est fourni par CD au 1er démarrage).
$ErrorActionPreference = 'Stop'

# ISO sans « Press any key » (créé une seule fois, partagé avec les autres images)
& (Join-Path $PSScriptRoot 'prepare-iso-noprompt.ps1')

$dir = Join-Path $PSScriptRoot '..\packer\windows-server-2025-core-sans-unattend' | Resolve-Path
Push-Location $dir
try {
    packer init .
    packer validate .
    # -on-error=abort : en cas d'échec, la VM n'est pas supprimée, on peut l'inspecter dans Hyper-V.
    packer build -force -on-error=abort .
}
finally { Pop-Location }
