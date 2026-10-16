#Requires -RunAsAdministrator
<#
.SYNOPSIS
  Prépare l'hôte Windows 11 pour Packer + Terraform (provider Hyper-V).
.NOTES
  Le provider Terraform taliesins/hyperv pilote Hyper-V à travers WinRM,
  même quand l'hôte est la machine locale. Il faut donc un listener WinRM.
  Configuration LAB : HTTP + Basic. À durcir (HTTPS) pour autre chose qu'un LAB.
#>
$ErrorActionPreference = 'Stop'

Write-Host '== Hyper-V ==' -ForegroundColor Cyan
$hv = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
if ($hv.State -ne 'Enabled') { throw 'Hyper-V n''est pas activé.' }
Write-Host 'Hyper-V OK'

Write-Host '== Outils ==' -ForegroundColor Cyan
foreach ($tool in 'packer', 'terraform') {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Write-Host "$tool OK" }
    else { Write-Warning "$tool introuvable : winget install Hashicorp.$((Get-Culture).TextInfo.ToTitleCase($tool))" }
}
$oscdimg = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits" -Recurse -Filter oscdimg.exe -ErrorAction SilentlyContinue | Select-Object -First 1
if ($oscdimg) { Write-Host "oscdimg OK ($($oscdimg.DirectoryName))" }
else { Write-Warning 'oscdimg.exe introuvable : installez le Windows ADK (Deployment Tools) et ajoutez son dossier au PATH.' }

Write-Host '== WinRM (pour le provider Terraform) ==' -ForegroundColor Cyan
try {
    Enable-PSRemoting -Force -SkipNetworkProfileCheck -ErrorAction Stop | Out-Null
}
catch {
    # Enable-PSRemoting échoue si la vérification du pare-feu ne marche pas (antivirus tiers, etc.).
    # On configure alors WinRM à la main : service + listener HTTP + règle de pare-feu.
    Write-Warning "Enable-PSRemoting a échoué ($($_.Exception.Message.Trim())). Configuration manuelle."
    Set-Service WinRM -StartupType Automatic
    Start-Service WinRM
    if (-not (Get-ChildItem WSMan:\localhost\Listener -ErrorAction SilentlyContinue | Where-Object Keys -contains 'Transport=HTTP')) {
        New-WSManInstance -ResourceURI winrm/config/Listener -SelectorSet @{ Address = '*'; Transport = 'HTTP' } -ValueSet @{} | Out-Null
    }
    netsh advfirewall firewall add rule name="WinRM-HTTP-Lab" dir=in action=allow protocol=TCP localport=5985 | Out-Null
}
Set-Item WSMan:\localhost\Service\AllowUnencrypted $true
Set-Item WSMan:\localhost\Service\Auth\Basic $true
Set-Item WSMan:\localhost\MaxEnvelopeSizekb 8192
Write-Host 'WinRM configuré (HTTP 5985, Basic).'

Write-Host '== Dossiers ==' -ForegroundColor Cyan
foreach ($d in 'C:\ISO', 'C:\VMS\images', 'C:\VMS\vms') { New-Item -ItemType Directory -Force $d | Out-Null }
Write-Host 'Dossiers créés. Déposez l''ISO Windows Server dans C:\ISO.'
