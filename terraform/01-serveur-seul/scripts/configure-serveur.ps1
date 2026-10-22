<#
.SYNOPSIS
  Configuration de base d'un serveur Core autonome (variante 01).

.DESCRIPTION
  Lancé SUR L'HÔTE par Terraform (terraform_data + local-exec), une fois la VM créée.
  Le mot de passe est lu dans la variable d'environnement LAB_ADMIN_PASSWORD, posée par Terraform.

  Lancement manuel possible (console PowerShell administrateur, depuis ce dossier) :
    $env:LAB_ADMIN_PASSWORD = 'P@ssw0rd!'
    .\scripts\configure-serveur.ps1 -VMName L01-SRV01 -ComputerName SRV01 -IPAddress 192.168.101.20
#>
param(
    [Parameter(Mandatory)][string]$VMName,
    [Parameter(Mandatory)][string]$ComputerName,
    [Parameter(Mandatory)][string]$IPAddress,
    [int]$PrefixLength = 24,
    [string]$Gateway = '',
    [string[]]$DnsServers = @(),
    [string]$AdminUser = 'Administrateur'
)
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'LabHelpers.psm1') -Force

if (-not $env:LAB_ADMIN_PASSWORD) { throw 'Variable d''environnement LAB_ADMIN_PASSWORD absente.' }

# Compte local de l'image Packer. « Administrateur » (et non « Administrator ») car l'ISO est en français.
$credLocal = New-LabCredential -UserName $AdminUser -Password $env:LAB_ADMIN_PASSWORD

Set-LabBaseConfig -VMName $VMName -Credential $credLocal -ComputerName $ComputerName `
    -IPAddress $IPAddress -PrefixLength $PrefixLength -Gateway $Gateway -DnsServers $DnsServers

# Petit bilan affiché dans la sortie de terraform apply.
Invoke-Command -VMName $VMName -Credential $credLocal -ScriptBlock {
    $os = Get-CimInstance Win32_OperatingSystem
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -notlike '127.*').IPAddress -join ', '
    "Nom      : $env:COMPUTERNAME"
    "Système  : $($os.Caption) (build $($os.BuildNumber))"
    "Adresse  : $ip"
} | ForEach-Object { Write-LabEtape $_ }

Write-LabEtape "Serveur $ComputerName prêt."
