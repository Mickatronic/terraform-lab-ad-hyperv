#Requires -RunAsAdministrator
# Construit l'image Windows Server 2025 DESKTOP EXPERIENCE (interface graphique) EN ANGLAIS (clavier français).
# Même principe que 01-build-image-core-en.ps1, sur le dossier packer\windows-server-2025-en.
$ErrorActionPreference = 'Stop'

# ISO anglais sans « Press any key » : créé une seule fois depuis C:\ISO\windows2025-en.iso.
& (Join-Path $PSScriptRoot 'prepare-iso-noprompt.ps1') `
    -SourceIso 'C:\ISO\windows2025-en.iso' `
    -DestIso   'C:\VMS\images\windows2025-en-noprompt.iso' `
    -WorkDir   'C:\VMS\images\iso-work-en'

$dir = Join-Path $PSScriptRoot '..\packer\windows-server-2025-en' | Resolve-Path
Push-Location $dir
try {
    packer init .
    packer validate .
    # -on-error=abort : en cas d'échec, la VM n'est pas supprimée, on peut l'inspecter dans Hyper-V.
    packer build -force -on-error=abort .
}
finally { Pop-Location }
