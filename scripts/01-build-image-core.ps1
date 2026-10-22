#Requires -RunAsAdministrator
# Construit l'image Windows Server 2025 SERVER CORE (sans interface graphique).
# Même principe que 01-build-image.ps1, mais sur le dossier packer\windows-server-2025-core.
$ErrorActionPreference = 'Stop'

# ISO sans « Press any key » (créé une seule fois, partagé avec la version Desktop Experience)
& (Join-Path $PSScriptRoot 'prepare-iso-noprompt.ps1')

$dir = Join-Path $PSScriptRoot '..\packer\windows-server-2025-core' | Resolve-Path
Push-Location $dir
try {
    packer init .
    packer validate .
    # -on-error=abort : en cas d'échec, la VM n'est pas supprimée, on peut l'inspecter dans Hyper-V.
    # (Supprimez-la à la main avant de relancer, ou repassez à "cleanup".)
    packer build -force -on-error=abort .
}
finally { Pop-Location }
