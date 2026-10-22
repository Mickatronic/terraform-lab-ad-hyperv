#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Crée une copie de l'ISO Windows qui démarre SANS « Press any key to boot from CD or DVD ».
.DESCRIPTION
  L'ISO Windows contient deux fichiers de démarrage UEFI :
    efisys.bin          -> avec l'invite « appuyez sur une touche »
    efisys_noprompt.bin -> sans invite
  On copie le contenu de l'ISO, puis on regénère un ISO avec oscdimg en utilisant efisys_noprompt.bin.
#>
param(
    [string]$SourceIso = 'C:\ISO\windows2025.iso',
    [string]$DestIso   = 'C:\VMS\images\windows2025-noprompt.iso',
    [string]$WorkDir   = 'C:\VMS\images\iso-work'
)
$ErrorActionPreference = 'Stop'

if (Test-Path $DestIso) { Write-Host "ISO déjà présent : $DestIso (supprimez-le pour le régénérer)"; return }

$oscdimg = (Get-Command oscdimg.exe -ErrorAction SilentlyContinue).Source
if (-not $oscdimg) { throw 'oscdimg.exe introuvable dans le PATH (installez le Windows ADK : Deployment Tools).' }

New-Item -ItemType Directory -Force (Split-Path $DestIso) | Out-Null
if (Test-Path $WorkDir) { Remove-Item $WorkDir -Recurse -Force }
New-Item -ItemType Directory -Force $WorkDir | Out-Null

Write-Host "Montage de $SourceIso ..." -ForegroundColor Cyan
$mount = Mount-DiskImage -ImagePath $SourceIso -PassThru
try {
    # La lettre de lecteur n'est pas toujours attribuée immédiatement après le montage.
    $vol = $null
    for ($i = 0; $i -lt 30 -and -not $vol.DriveLetter; $i++) {
        Start-Sleep -Seconds 1
        $vol = Get-DiskImage -ImagePath $SourceIso | Get-Volume
    }
    if (-not $vol.DriveLetter) { throw "Aucune lettre de lecteur pour l'ISO monté ($SourceIso)." }
    $root = "$($vol.DriveLetter):\"
    $noPrompt = Join-Path $root 'efi\microsoft\boot\efisys_noprompt.bin'
    if (-not (Test-Path $noPrompt)) { throw "efisys_noprompt.bin absent de l'ISO ($noPrompt)." }

    Write-Host 'Copie du contenu (~6 Go, quelques minutes) ...' -ForegroundColor Cyan
    robocopy $root $WorkDir /E /NFL /NDL /NJH /NJS /NP | Out-Null
    if ($LASTEXITCODE -ge 8) { throw "robocopy a échoué (code $LASTEXITCODE)" }
    $label = $vol.FileSystemLabel
    if (-not $label) { $label = 'WS2025' }
}
finally {
    Dismount-DiskImage -ImagePath $SourceIso | Out-Null
}

Write-Host 'Création de l''ISO sans invite ...' -ForegroundColor Cyan
$boot = "2#p0,e,b$WorkDir\boot\etfsboot.com#pEF,e,b$WorkDir\efi\microsoft\boot\efisys_noprompt.bin"
& $oscdimg -m -o -u2 -udfver102 -l"$label" "-bootdata:$boot" $WorkDir $DestIso
if ($LASTEXITCODE -ne 0) { throw "oscdimg a échoué (code $LASTEXITCODE)" }

Remove-Item $WorkDir -Recurse -Force
Write-Host "OK : $DestIso" -ForegroundColor Green
