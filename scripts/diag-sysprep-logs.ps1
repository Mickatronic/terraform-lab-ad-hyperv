#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Lit les journaux sysprep (Panther) d'une VM de build Packer devenue injoignable.
.DESCRIPTION
  Quand sysprep échoue après avoir coupé le réseau, ni WinRM ni PowerShell Direct ne répondent.
  On lit alors les journaux directement sur le disque de la VM, depuis l'hôte :
    1. on éteint la VM (le build est de toute façon perdu) ;
    2. on monte son VHDX en LECTURE SEULE ;
    3. on affiche setuperr.log (erreurs) et la fin de setupact.log (déroulement) ;
    4. on démonte le disque.
  Les journaux sont aussi copiés dans C:\VMS\images\diag-sysprep\ pour pouvoir les relire.
#>
param(
    [string]$VMName = 'ws2025-core-golden',
    [string]$OutDir = 'C:\VMS\images\diag-sysprep'
)
$ErrorActionPreference = 'Stop'

$vhd = (Get-VMHardDiskDrive -VMName $VMName | Select-Object -First 1).Path
if (-not $vhd) { throw "Aucun disque trouvé pour la VM $VMName" }
Write-Host "Disque de la VM : $vhd" -ForegroundColor Cyan

if ((Get-VM $VMName).State -ne 'Off') {
    Write-Host "Arrêt forcé de $VMName ..." -ForegroundColor Cyan
    Stop-VM $VMName -TurnOff -Force
}

$disk = Mount-VHD $vhd -ReadOnly -Passthru | Get-Disk
try {
    # Sur un disque monté en lecture seule, Windows n'attribue pas toujours de lettre : on en ajoute une si besoin.
    $part = $disk | Get-Partition | Where-Object { ($_ | Get-Volume).FileSystemLabel -eq 'Windows' }
    if (-not $part.DriveLetter) {
        $part | Add-PartitionAccessPath -AssignDriveLetter
        $part = $part | Get-Partition
    }
    $panther = "$($part.DriveLetter):\Windows\System32\Sysprep\Panther"
    New-Item -ItemType Directory -Force $OutDir | Out-Null
    Copy-Item "$panther\*.log" $OutDir -Force -ErrorAction SilentlyContinue

    Write-Host '=== setuperr.log ===' -ForegroundColor Yellow
    Get-Content "$panther\setuperr.log" -ErrorAction SilentlyContinue
    Write-Host '=== setupact.log (80 dernières lignes) ===' -ForegroundColor Yellow
    Get-Content "$panther\setupact.log" -Tail 80 -ErrorAction SilentlyContinue
}
finally {
    Dismount-VHD $vhd
}
Write-Host "Journaux copiés dans $OutDir" -ForegroundColor Green
